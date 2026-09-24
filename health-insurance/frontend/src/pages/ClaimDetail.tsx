import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ArrowRight, Download, Trash2, Upload } from 'lucide-react'
import { useRef, useState } from 'react'
import toast from 'react-hot-toast'
import { claimsApi, documentsApi } from '../lib/api'
import { formatCurrency, formatDate, STATUS_LABELS, getStatusBadge, CLAIM_TYPE_LABELS, DOCUMENT_TYPE_LABELS } from '../lib/utils'

export default function ClaimDetail() {
  const { id } = useParams<{ id: string }>()
  const qc = useQueryClient()
  const fileRef = useRef<HTMLInputElement>(null)
  const [statusForm, setStatusForm] = useState({ status: '', approved_amount: '', notes: '', rejection_reason: '' })

  const { data: claim, isLoading } = useQuery({
    queryKey: ['claim', id],
    queryFn: () => claimsApi.get(Number(id)),
    onSuccess: (c: any) => setStatusForm({ status: c.status, approved_amount: c.approved_amount, notes: c.notes, rejection_reason: c.rejection_reason }),
  } as any)

  const updateStatus = useMutation({
    mutationFn: () => claimsApi.updateStatus(Number(id), {
      status: statusForm.status,
      approved_amount: statusForm.approved_amount ? Number(statusForm.approved_amount) : undefined,
      notes: statusForm.notes,
      rejection_reason: statusForm.rejection_reason,
    }),
    onSuccess: () => { toast.success('تم تحديث الحالة'); qc.invalidateQueries({ queryKey: ['claim', id] }) },
    onError: (e: any) => toast.error(e.response?.data?.detail || 'حدث خطأ'),
  })

  const uploadDoc = useMutation({
    mutationFn: ({ file, type }: { file: File; type: string }) => documentsApi.upload(Number(id), file, type),
    onSuccess: () => { toast.success('تم رفع المستند'); qc.invalidateQueries({ queryKey: ['claim', id] }) },
  })

  const deleteDoc = useMutation({
    mutationFn: (docId: number) => documentsApi.delete(docId),
    onSuccess: () => { toast.success('تم حذف المستند'); qc.invalidateQueries({ queryKey: ['claim', id] }) },
  })

  if (isLoading) return <div className="p-8 text-center text-slate-400">جارٍ التحميل...</div>
  if (!claim) return <div className="p-8 text-center text-red-400">المطالبة غير موجودة</div>

  return (
    <div className="space-y-6 max-w-5xl">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link to="/claims" className="text-slate-400 hover:text-slate-600"><ArrowRight className="w-5 h-5" /></Link>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-slate-900 font-mono">{claim.claim_number}</h1>
            <span className={getStatusBadge(claim.status)}>{STATUS_LABELS[claim.status]}</span>
          </div>
          <p className="text-sm text-slate-500 mt-0.5">
            <Link to={`/employees/${claim.employee_id}`} className="text-blue-600 hover:underline">{claim.employee_name}</Link>
            {' · '}{claim.hospital_name}{' · '}{claim.claim_date}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-5">
          {/* Financial Breakdown */}
          <div className="card p-6">
            <h3 className="font-semibold text-slate-800 mb-4">التفاصيل المالية</h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              <div className="bg-slate-50 rounded-xl p-4 text-center">
                <p className="text-xs text-slate-500">قيمة الفاتورة</p>
                <p className="text-lg font-bold text-slate-800 mt-1">{formatCurrency(claim.invoice_amount)}</p>
              </div>
              <div className={`rounded-xl p-4 text-center ${claim.claim_type === 'inpatient' ? 'bg-emerald-500' : 'bg-amber-500'} text-white`}>
                <p className="text-xs opacity-80">نسبة التغطية</p>
                <p className="text-3xl font-bold mt-1">{claim.coverage_pct}%</p>
                <p className="text-xs opacity-70 mt-0.5">{CLAIM_TYPE_LABELS[claim.claim_type]}</p>
              </div>
              <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 text-center">
                <p className="text-xs text-slate-500">مبلغ التأمين</p>
                <p className="text-lg font-bold text-emerald-600 mt-1">{formatCurrency(claim.insurance_amount)}</p>
              </div>
              <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-center">
                <p className="text-xs text-slate-500">تحمّل الموظف</p>
                <p className="text-lg font-bold text-red-500 mt-1">{formatCurrency(claim.employee_amount)}</p>
              </div>
            </div>
            {claim.approved_amount !== claim.insurance_amount && (
              <div className="mt-4 bg-blue-50 border border-blue-200 rounded-lg p-3 text-sm">
                المبلغ المعتمد فعلياً: <strong className="text-blue-700">{formatCurrency(claim.approved_amount)}</strong>
              </div>
            )}
            {claim.rejection_reason && (
              <div className="mt-4 bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-700">
                <strong>سبب الرفض:</strong> {claim.rejection_reason}
              </div>
            )}
            {claim.notes && (
              <div className="mt-3 text-sm text-slate-600"><strong>ملاحظات:</strong> {claim.notes}</div>
            )}
          </div>

          {/* Claim Details */}
          <div className="card p-6">
            <h3 className="font-semibold text-slate-800 mb-4">تفاصيل الخدمة الطبية</h3>
            <dl className="grid grid-cols-2 gap-4 text-sm">
              {[
                ['الموظف', claim.employee_name],
                ['المستفيد', claim.beneficiary_name],
                ['نوع المطالبة', CLAIM_TYPE_LABELS[claim.claim_type]],
                ['تاريخ الخدمة', claim.claim_date],
                ['المستشفى / العيادة', claim.hospital_name],
                ['التشخيص', claim.diagnosis],
              ].map(([k, v]) => (
                <div key={k}>
                  <dt className="text-slate-400 mb-0.5 text-xs uppercase tracking-wider">{k}</dt>
                  <dd className="font-medium text-slate-800">{v}</dd>
                </div>
              ))}
            </dl>
          </div>

          {/* Documents */}
          <div className="card p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold text-slate-800">المستندات ({claim.documents?.length || 0})</h3>
              <button onClick={() => fileRef.current?.click()} className="btn-secondary text-xs py-1.5">
                <Upload className="w-3.5 h-3.5" /> رفع مستند
              </button>
              <input ref={fileRef} type="file" className="hidden" accept=".pdf,image/*"
                onChange={(e) => { const f = e.target.files?.[0]; if (f) uploadDoc.mutate({ file: f, type: 'invoice' }) }}
              />
            </div>
            {claim.documents?.length > 0 ? (
              <div className="grid grid-cols-2 gap-3">
                {claim.documents.map((doc: any) => (
                  <div key={doc.id} className="border border-slate-200 rounded-xl p-4 flex items-start gap-3">
                    <div className="w-10 h-10 bg-blue-50 rounded-lg flex items-center justify-center shrink-0">
                      <Download className="w-5 h-5 text-blue-500" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-medium text-slate-700 truncate">{doc.original_filename}</p>
                      <p className="text-xs text-slate-400 mt-0.5">{DOCUMENT_TYPE_LABELS[doc.document_type]}</p>
                    </div>
                    <div className="flex gap-1">
                      <a href={`/api/documents/${doc.id}/download`} target="_blank" className="text-blue-500 hover:text-blue-700 p-1">
                        <Download className="w-4 h-4" />
                      </a>
                      <button onClick={() => deleteDoc.mutate(doc.id)} className="text-red-400 hover:text-red-600 p-1">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-slate-400 text-sm text-center py-4">لا توجد مستندات مرفقة</p>
            )}
          </div>
        </div>

        {/* Status Update Panel */}
        <div>
          <div className="card p-5 sticky top-4">
            <h3 className="font-semibold text-slate-800 mb-4">تحديث حالة المطالبة</h3>
            <div className="space-y-3">
              <div>
                <label className="form-label">الحالة</label>
                <select className="input-field" value={statusForm.status}
                  onChange={(e) => setStatusForm(f => ({ ...f, status: e.target.value }))}>
                  {Object.entries(STATUS_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
              </div>
              <div>
                <label className="form-label">المبلغ المعتمد (ريال)</label>
                <input type="number" step="0.01" className="input-field" value={statusForm.approved_amount}
                  onChange={(e) => setStatusForm(f => ({ ...f, approved_amount: e.target.value }))} />
              </div>
              <div>
                <label className="form-label">ملاحظات</label>
                <textarea className="input-field" rows={2} value={statusForm.notes}
                  onChange={(e) => setStatusForm(f => ({ ...f, notes: e.target.value }))} />
              </div>
              <div>
                <label className="form-label">سبب الرفض</label>
                <textarea className="input-field" rows={2} value={statusForm.rejection_reason}
                  onChange={(e) => setStatusForm(f => ({ ...f, rejection_reason: e.target.value }))} />
              </div>
              <button
                onClick={() => updateStatus.mutate()}
                disabled={updateStatus.isPending}
                className="btn-primary w-full justify-center"
              >
                {updateStatus.isPending ? 'جارٍ الحفظ...' : 'حفظ التغييرات'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
