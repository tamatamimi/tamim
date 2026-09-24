import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ArrowRight, Plus, FileText, UserPlus } from 'lucide-react'
import { useState } from 'react'
import toast from 'react-hot-toast'
import { employeesApi, claimsApi, familyApi } from '../lib/api'
import { formatCurrency, formatDate, STATUS_LABELS, getStatusBadge, CLAIM_TYPE_LABELS, RELATION_LABELS, currentYear } from '../lib/utils'

const EMPTY_MEMBER = { full_name: '', national_id: '', relation: 'spouse', date_of_birth: '', is_active: true }

export default function EmployeeDetail() {
  const { id } = useParams<{ id: string }>()
  const [year, setYear] = useState(currentYear())
  const [showFamilyModal, setShowFamilyModal] = useState(false)
  const [memberForm, setMemberForm] = useState(EMPTY_MEMBER)
  const qc = useQueryClient()

  const { data: emp, isLoading } = useQuery({
    queryKey: ['employee', id, year],
    queryFn: () => employeesApi.get(Number(id), year),
  })

  const { data: claims = [] } = useQuery({
    queryKey: ['claims', 'employee', id, year],
    queryFn: () => claimsApi.list({ employee_id: id, year }),
  })

  const { data: family = [] } = useQuery({
    queryKey: ['family', id, year],
    queryFn: () => employeesApi.getFamily(Number(id), year),
  })

  const addMember = useMutation({
    mutationFn: (data: typeof EMPTY_MEMBER) => familyApi.create({ ...data, employee_id: Number(id) }),
    onSuccess: () => {
      toast.success('تم إضافة فرد العائلة')
      qc.invalidateQueries({ queryKey: ['employee', id] })
      qc.invalidateQueries({ queryKey: ['family', id] })
      setShowFamilyModal(false)
      setMemberForm(EMPTY_MEMBER)
    },
    onError: (e: any) => toast.error(e.response?.data?.detail || 'حدث خطأ'),
  })

  if (isLoading) return <div className="p-8 text-center text-slate-400">جارٍ التحميل...</div>
  if (!emp) return <div className="p-8 text-center text-red-400">الموظف غير موجود</div>

  const usagePct = Math.min(Number(emp.usage_pct || 0), 100)

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link to="/employees" className="text-slate-400 hover:text-slate-600">
          <ArrowRight className="w-5 h-5" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-slate-900">{emp.full_name}</h1>
          <p className="text-sm text-slate-500">{emp.employee_id} · {emp.department}</p>
        </div>
        <div className="mr-auto flex gap-2">
          <select
            className="input-field w-28"
            value={year}
            onChange={(e) => setYear(Number(e.target.value))}
          >
            {[0, 1, 2, 3].map((i) => {
              const y = currentYear() - i
              return <option key={y} value={y}>{y}</option>
            })}
          </select>
          <Link to={`/claims/new?employee=${id}`} className="btn-primary">
            <Plus className="w-4 h-4" /> مطالبة جديدة
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Employee Info */}
        <div className="card p-5">
          <h3 className="font-semibold text-slate-800 mb-4">بيانات الموظف</h3>
          <dl className="space-y-2 text-sm">
            {[
              ['رقم الهوية', emp.national_id],
              ['الجنس', emp.gender === 'M' ? 'ذكر' : 'أنثى'],
              ['تاريخ الميلاد', formatDate(emp.date_of_birth)],
              ['تاريخ التوظيف', formatDate(emp.hire_date)],
              ['المسمى الوظيفي', emp.job_title || '-'],
              ['الجوال', emp.phone || '-'],
            ].map(([k, v]) => (
              <div key={k} className="flex justify-between">
                <dt className="text-slate-500">{k}</dt>
                <dd className="font-medium text-slate-700">{v}</dd>
              </div>
            ))}
          </dl>
        </div>

        {/* Annual Usage */}
        <div className="card p-5">
          <h3 className="font-semibold text-slate-800 mb-4">استخدام التأمين ({year})</h3>
          {emp.settings ? (
            <>
              <div className="space-y-1 mb-3">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">المستخدم</span>
                  <span className="font-bold text-slate-800">{formatCurrency(emp.annual_used || 0)}</span>
                </div>
                <div className="h-3 bg-slate-100 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${usagePct > 80 ? 'bg-red-500' : usagePct > 50 ? 'bg-amber-500' : 'bg-emerald-500'}`}
                    style={{ width: `${usagePct}%` }}
                  />
                </div>
                <div className="flex justify-between text-xs text-slate-400">
                  <span>{usagePct.toFixed(1)}%</span>
                  <span>السقف: {formatCurrency(emp.annual_limit || 0)}</span>
                </div>
              </div>
              <div className="bg-emerald-50 rounded-lg p-3 text-center">
                <p className="text-xs text-slate-500">المتبقي</p>
                <p className="text-lg font-bold text-emerald-600">{formatCurrency(emp.annual_remaining || 0)}</p>
              </div>
              <div className="grid grid-cols-2 gap-3 mt-3 text-center">
                <div className="bg-blue-50 rounded-lg p-2">
                  <p className="text-xs text-slate-500">تغطية الرقود</p>
                  <p className="font-bold text-blue-600 text-lg">{emp.settings.inpatient_pct}%</p>
                </div>
                <div className="bg-amber-50 rounded-lg p-2">
                  <p className="text-xs text-slate-500">طوارئ/عيادات</p>
                  <p className="font-bold text-amber-600 text-lg">{emp.settings.outpatient_pct}%</p>
                </div>
              </div>
            </>
          ) : <p className="text-slate-400 text-sm">لا توجد سياسة تأمين</p>}
        </div>

        {/* Family Members */}
        <div className="card p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-slate-800">أفراد العائلة</h3>
            <button onClick={() => setShowFamilyModal(true)} className="btn-secondary py-1.5 text-xs">
              <UserPlus className="w-3.5 h-3.5" /> إضافة
            </button>
          </div>
          <div className="space-y-3">
            {family.map((m: any) => {
              const limit = emp.settings?.family_annual_limit || 0
              const pct = limit > 0 ? Math.min((m.annual_used / limit) * 100, 100) : 0
              return (
                <div key={m.id} className="border border-slate-100 rounded-lg p-3">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium">{m.full_name}</span>
                    <span className="text-slate-400 text-xs">{RELATION_LABELS[m.relation]}</span>
                  </div>
                  <div className="h-1.5 bg-slate-100 rounded-full mt-2 overflow-hidden">
                    <div className="h-full bg-blue-400 rounded-full" style={{ width: `${pct}%` }} />
                  </div>
                  <div className="flex justify-between text-xs text-slate-400 mt-1">
                    <span>مستخدم: {formatCurrency(m.annual_used || 0)}</span>
                    <span>متبقي: {formatCurrency(m.annual_remaining ?? limit)}</span>
                  </div>
                </div>
              )
            })}
            {family.length === 0 && <p className="text-slate-400 text-sm text-center py-3">لا يوجد أفراد عائلة</p>}
          </div>
        </div>
      </div>

      {/* Claims History */}
      <div className="card">
        <div className="p-5 border-b border-slate-100 flex items-center gap-2">
          <FileText className="w-4 h-4 text-slate-400" />
          <h3 className="font-semibold text-slate-800">مطالبات {year}</h3>
          <span className="text-xs bg-slate-100 text-slate-600 rounded-full px-2 py-0.5">{claims.length}</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr>
                {['رقم المطالبة', 'المستفيد', 'النوع', 'التاريخ', 'الفاتورة', 'التغطية', 'التأمين', 'تحمل الموظف', 'الحالة'].map((h) => (
                  <th key={h} className="text-right px-4 py-3 text-xs font-semibold text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {claims.map((c: any) => (
                <tr key={c.id} className="hover:bg-slate-50">
                  <td className="px-4 py-3">
                    <Link to={`/claims/${c.id}`} className="text-blue-600 font-mono hover:underline text-xs">{c.claim_number}</Link>
                  </td>
                  <td className="px-4 py-3">{c.beneficiary_name}</td>
                  <td className="px-4 py-3">{CLAIM_TYPE_LABELS[c.claim_type]}</td>
                  <td className="px-4 py-3">{c.claim_date}</td>
                  <td className="px-4 py-3">{formatCurrency(c.invoice_amount)}</td>
                  <td className={`px-4 py-3 font-bold ${c.claim_type === 'inpatient' ? 'text-emerald-600' : 'text-amber-600'}`}>{c.coverage_pct}%</td>
                  <td className="px-4 py-3 text-emerald-600 font-semibold">{formatCurrency(c.insurance_amount)}</td>
                  <td className="px-4 py-3 text-red-500">{formatCurrency(c.employee_amount)}</td>
                  <td className="px-4 py-3"><span className={getStatusBadge(c.status)}>{STATUS_LABELS[c.status]}</span></td>
                </tr>
              ))}
              {claims.length === 0 && (
                <tr><td colSpan={9} className="text-center py-8 text-slate-400">لا توجد مطالبات لهذه السنة</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Family Modal */}
      {showFamilyModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
            <div className="p-5 border-b flex items-center justify-between">
              <h2 className="font-bold">إضافة فرد عائلة</h2>
              <button onClick={() => setShowFamilyModal(false)} className="text-slate-400 hover:text-slate-600 text-2xl">&times;</button>
            </div>
            <form className="p-5 space-y-3" onSubmit={(e) => { e.preventDefault(); addMember.mutate(memberForm as any) }}>
              <div>
                <label className="form-label">الاسم الكامل *</label>
                <input className="input-field" required value={memberForm.full_name}
                  onChange={(e) => setMemberForm(f => ({ ...f, full_name: e.target.value }))} />
              </div>
              <div>
                <label className="form-label">صلة القرابة *</label>
                <select className="input-field" value={memberForm.relation}
                  onChange={(e) => setMemberForm(f => ({ ...f, relation: e.target.value }))}>
                  {Object.entries(RELATION_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
              </div>
              <div>
                <label className="form-label">تاريخ الميلاد *</label>
                <input type="date" className="input-field" required value={memberForm.date_of_birth}
                  onChange={(e) => setMemberForm(f => ({ ...f, date_of_birth: e.target.value }))} />
              </div>
              <div className="flex gap-3 pt-1">
                <button type="submit" disabled={addMember.isPending} className="btn-primary flex-1 justify-center">حفظ</button>
                <button type="button" onClick={() => setShowFamilyModal(false)} className="btn-secondary flex-1 justify-center">إلغاء</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
