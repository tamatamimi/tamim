import { useState, useEffect, useCallback } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useDropzone } from 'react-dropzone'
import { Upload, FileText, X, CheckCircle } from 'lucide-react'
import toast from 'react-hot-toast'
import { employeesApi, claimsApi, documentsApi, settingsApi, Employee } from '../lib/api'
import { formatCurrency, RELATION_LABELS, DOCUMENT_TYPE_LABELS } from '../lib/utils'

interface PendingFile { file: File; type: string }

export default function NewClaim() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const qc = useQueryClient()

  const [form, setForm] = useState({
    employee_id: searchParams.get('employee') || '',
    beneficiary_type: 'employee',
    family_member_id: '',
    claim_type: 'outpatient',
    claim_date: new Date().toISOString().split('T')[0],
    hospital_name: '',
    diagnosis: '',
    invoice_amount: '',
    notes: '',
  })
  const [pendingFiles, setPendingFiles] = useState<PendingFile[]>([])
  const [preview, setPreview] = useState<{ insurance: number; employee: number; pct: number } | null>(null)

  const { data: employees = [] } = useQuery({ queryKey: ['employees'], queryFn: () => employeesApi.list() })
  const { data: settings } = useQuery({ queryKey: ['settings-active'], queryFn: () => settingsApi.getActive() })

  const selectedEmp: Employee | undefined = employees.find((e: Employee) => String(e.id) === form.employee_id)

  // Live preview calculation
  useEffect(() => {
    const amount = parseFloat(form.invoice_amount)
    if (!amount || !settings) { setPreview(null); return }
    const pct = form.claim_type === 'inpatient' ? settings.inpatient_pct : settings.outpatient_pct
    const capped = Math.min(amount, settings.max_per_claim)
    const ins = parseFloat((capped * pct / 100).toFixed(2))
    const emp = parseFloat((amount - ins).toFixed(2))
    setPreview({ insurance: ins, employee: emp, pct })
  }, [form.invoice_amount, form.claim_type, settings])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    accept: { 'application/pdf': [], 'image/*': [] },
    onDrop: (files) => setPendingFiles((prev) => [...prev, ...files.map((f) => ({ file: f, type: 'invoice' }))]),
  })

  const createClaim = useMutation({
    mutationFn: async () => {
      const claim = await claimsApi.create({
        ...form,
        employee_id: Number(form.employee_id),
        family_member_id: form.family_member_id ? Number(form.family_member_id) : undefined,
        invoice_amount: parseFloat(form.invoice_amount),
      } as any)
      for (const pf of pendingFiles) {
        await documentsApi.upload(claim.id, pf.file, pf.type)
      }
      return claim
    },
    onSuccess: (claim) => {
      toast.success(`تم تقديم المطالبة: ${claim.claim_number}`)
      qc.invalidateQueries({ queryKey: ['claims'] })
      navigate(`/claims/${claim.id}`)
    },
    onError: (e: any) => toast.error(e.response?.data?.detail || 'حدث خطأ'),
  })

  const f = (field: string) => ({
    value: (form as any)[field],
    onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
      setForm((p) => ({ ...p, [field]: e.target.value })),
  })

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">مطالبة تأمين جديدة</h1>
        <p className="text-sm text-slate-500 mt-0.5">أدخل بيانات الخدمة الطبية والمستندات الثبوتية</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-5">
          {/* Claim Info */}
          <div className="card p-6 space-y-4">
            <h3 className="font-semibold text-slate-800 border-b border-slate-100 pb-3">بيانات المطالبة</h3>

            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2">
                <label className="form-label">الموظف *</label>
                <select className="input-field" {...f('employee_id')} required>
                  <option value="">-- اختر الموظف --</option>
                  {employees.map((e: Employee) => (
                    <option key={e.id} value={e.id}>{e.full_name} ({e.employee_id})</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="form-label">المستفيد *</label>
                <select className="input-field" {...f('beneficiary_type')}>
                  <option value="employee">الموظف نفسه</option>
                  <option value="family">فرد من العائلة</option>
                </select>
              </div>

              {form.beneficiary_type === 'family' && selectedEmp && (
                <div>
                  <label className="form-label">فرد العائلة *</label>
                  <select className="input-field" {...f('family_member_id')} required>
                    <option value="">-- اختر --</option>
                    {selectedEmp.family_members?.map((m) => (
                      <option key={m.id} value={m.id}>{m.full_name} ({RELATION_LABELS[m.relation]})</option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {/* Claim Type Visual Cards */}
            <div>
              <label className="form-label">نوع المطالبة *</label>
              <div className="grid grid-cols-3 gap-3">
                {[
                  { value: 'inpatient', label: 'مريض داخلي', sub: 'رقود في المستشفى', pct: settings?.inpatient_pct ?? 90, color: 'border-emerald-400 bg-emerald-50', textColor: 'text-emerald-700' },
                  { value: 'outpatient', label: 'عيادات خارجية', sub: 'بدون رقود', pct: settings?.outpatient_pct ?? 70, color: 'border-amber-400 bg-amber-50', textColor: 'text-amber-700' },
                  { value: 'emergency', label: 'طوارئ', sub: 'حالات طارئة', pct: settings?.outpatient_pct ?? 70, color: 'border-red-400 bg-red-50', textColor: 'text-red-700' },
                ].map((t) => (
                  <button
                    key={t.value}
                    type="button"
                    onClick={() => setForm((p) => ({ ...p, claim_type: t.value }))}
                    className={`border-2 rounded-xl p-4 text-center transition-all ${
                      form.claim_type === t.value ? t.color + ' border-2' : 'border-slate-200 bg-white hover:border-slate-300'
                    }`}
                  >
                    <div className={`text-2xl font-bold ${form.claim_type === t.value ? t.textColor : 'text-slate-700'}`}>{t.pct}%</div>
                    <div className="font-semibold text-sm mt-1">{t.label}</div>
                    <div className="text-xs text-slate-400 mt-0.5">{t.sub}</div>
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="form-label">تاريخ الخدمة الطبية *</label>
                <input type="date" className="input-field" {...f('claim_date')} required />
              </div>
              <div>
                <label className="form-label">قيمة الفاتورة (ريال) *</label>
                <input type="number" step="0.01" min="0.01" className="input-field" placeholder="0.00" {...f('invoice_amount')} required />
              </div>
              <div className="col-span-2">
                <label className="form-label">اسم المستشفى / العيادة *</label>
                <input className="input-field" {...f('hospital_name')} required />
              </div>
              <div className="col-span-2">
                <label className="form-label">التشخيص / السبب الطبي *</label>
                <textarea className="input-field" rows={3} {...f('diagnosis')} required />
              </div>
              <div className="col-span-2">
                <label className="form-label">ملاحظات</label>
                <textarea className="input-field" rows={2} {...f('notes')} />
              </div>
            </div>
          </div>

          {/* Documents */}
          <div className="card p-6">
            <h3 className="font-semibold text-slate-800 mb-4">المستندات الثبوتية</h3>
            <div
              {...getRootProps()}
              className={`border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-colors ${
                isDragActive ? 'border-blue-400 bg-blue-50' : 'border-slate-200 hover:border-blue-300 hover:bg-slate-50'
              }`}
            >
              <input {...getInputProps()} />
              <Upload className="w-10 h-10 text-slate-300 mx-auto mb-3" />
              <p className="text-slate-600 font-medium">اسحب وأفلت الملفات هنا</p>
              <p className="text-sm text-slate-400 mt-1">أو اضغط للاختيار — PDF، صور (حتى 10MB)</p>
            </div>

            {pendingFiles.length > 0 && (
              <div className="mt-4 space-y-2">
                {pendingFiles.map((pf, i) => (
                  <div key={i} className="flex items-center gap-3 bg-slate-50 rounded-lg p-3">
                    <FileText className="w-5 h-5 text-blue-500 shrink-0" />
                    <span className="text-sm flex-1 truncate">{pf.file.name}</span>
                    <select
                      className="input-field w-40 text-xs py-1"
                      value={pf.type}
                      onChange={(e) => setPendingFiles((p) => p.map((f, j) => j === i ? { ...f, type: e.target.value } : f))}
                    >
                      {Object.entries(DOCUMENT_TYPE_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                    </select>
                    <button onClick={() => setPendingFiles((p) => p.filter((_, j) => j !== i))} className="text-red-400 hover:text-red-600">
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Sidebar: Preview */}
        <div className="space-y-4">
          <div className="card p-5 sticky top-4">
            <h3 className="font-semibold text-slate-800 mb-4">معاينة التغطية</h3>
            {preview ? (
              <div className="space-y-3">
                <div className="flex justify-between text-sm border-b border-slate-100 pb-3">
                  <span className="text-slate-500">قيمة الفاتورة</span>
                  <span className="font-medium">{formatCurrency(parseFloat(form.invoice_amount))}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">نسبة التغطية</span>
                  <span className={`font-bold text-lg ${form.claim_type === 'inpatient' ? 'text-emerald-600' : 'text-amber-600'}`}>{preview.pct}%</span>
                </div>
                <div className="bg-emerald-50 rounded-xl p-4 text-center">
                  <p className="text-xs text-slate-500 mb-1">مبلغ التأمين</p>
                  <p className="text-2xl font-bold text-emerald-600">{formatCurrency(preview.insurance)}</p>
                </div>
                <div className="bg-red-50 rounded-xl p-4 text-center">
                  <p className="text-xs text-slate-500 mb-1">تحمّل الموظف</p>
                  <p className="text-xl font-bold text-red-500">{formatCurrency(preview.employee)}</p>
                </div>
                {settings && (
                  <p className="text-xs text-slate-400 text-center">السقف الأقصى للمطالبة: {formatCurrency(settings.max_per_claim)}</p>
                )}
              </div>
            ) : (
              <p className="text-slate-400 text-sm text-center py-4">أدخل قيمة الفاتورة لمعاينة التغطية</p>
            )}
          </div>

          {/* Insurance Rules Card */}
          <div className="card p-5">
            <h3 className="font-semibold text-slate-800 mb-3 text-sm">قواعد التغطية</h3>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm">
                <span className="w-12 text-center bg-emerald-100 text-emerald-700 font-bold rounded-md py-0.5">{settings?.inpatient_pct ?? 90}%</span>
                <span className="text-slate-600">مريض داخلي (رقود)</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <span className="w-12 text-center bg-amber-100 text-amber-700 font-bold rounded-md py-0.5">{settings?.outpatient_pct ?? 70}%</span>
                <span className="text-slate-600">طوارئ / عيادات</span>
              </div>
            </div>
          </div>

          <button
            onClick={() => createClaim.mutate()}
            disabled={createClaim.isPending || !form.employee_id || !form.invoice_amount || !form.hospital_name || !form.diagnosis}
            className="btn-primary w-full justify-center py-3"
          >
            {createClaim.isPending ? 'جارٍ الإرسال...' : (
              <><CheckCircle className="w-5 h-5" /> تقديم المطالبة</>
            )}
          </button>
        </div>
      </div>
    </div>
  )
}
