import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Search, Plus, Eye, Users } from 'lucide-react'
import toast from 'react-hot-toast'
import { employeesApi, familyApi, Employee } from '../lib/api'
import { formatDate } from '../lib/utils'

const EMPTY_EMP = {
  employee_id: '', full_name: '', national_id: '', gender: 'M' as const,
  date_of_birth: '', hire_date: '', department: '', job_title: '', phone: '', email: '', is_active: true,
}

export default function EmployeeList() {
  const [q, setQ] = useState('')
  const [showModal, setShowModal] = useState(false)
  const [form, setForm] = useState(EMPTY_EMP)
  const qc = useQueryClient()

  const { data: employees = [], isLoading } = useQuery({
    queryKey: ['employees', q],
    queryFn: () => employeesApi.list(q),
  })

  const create = useMutation({
    mutationFn: (data: typeof EMPTY_EMP) => employeesApi.create(data),
    onSuccess: () => {
      toast.success('تم إضافة الموظف')
      qc.invalidateQueries({ queryKey: ['employees'] })
      setShowModal(false)
      setForm(EMPTY_EMP)
    },
    onError: (e: any) => toast.error(e.response?.data?.detail || 'حدث خطأ'),
  })

  const inp = (field: string) => ({
    className: 'input-field',
    value: (form as any)[field],
    onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
      setForm((f) => ({ ...f, [field]: e.target.value })),
  })

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">الموظفون</h1>
          <p className="text-sm text-slate-500 mt-0.5">{employees.length} موظف نشط</p>
        </div>
        <button onClick={() => setShowModal(true)} className="btn-primary">
          <Plus className="w-4 h-4" /> إضافة موظف
        </button>
      </div>

      {/* Search */}
      <div className="card p-3">
        <div className="relative">
          <Search className="w-4 h-4 absolute top-1/2 -translate-y-1/2 right-3 text-slate-400" />
          <input
            className="input-field pr-9"
            placeholder="بحث بالاسم أو رقم الموظف أو القسم..."
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-50 border-b border-slate-100">
              <tr>
                {['رقم الموظف', 'الاسم', 'القسم', 'المسمى الوظيفي', 'الجوال', 'أفراد العائلة', ''].map((h) => (
                  <th key={h} className="text-right px-5 py-3 text-xs font-semibold text-slate-500 uppercase">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {isLoading
                ? Array.from({ length: 4 }).map((_, i) => (
                    <tr key={i}>
                      {Array.from({ length: 7 }).map((_, j) => (
                        <td key={j} className="px-5 py-4">
                          <div className="h-4 bg-slate-100 rounded animate-pulse" />
                        </td>
                      ))}
                    </tr>
                  ))
                : employees.map((emp: Employee) => (
                    <tr key={emp.id} className="hover:bg-blue-50/30 transition-colors">
                      <td className="px-5 py-4 font-mono text-blue-600">{emp.employee_id}</td>
                      <td className="px-5 py-4 font-semibold text-slate-900">{emp.full_name}</td>
                      <td className="px-5 py-4 text-slate-600">{emp.department || '-'}</td>
                      <td className="px-5 py-4 text-slate-600">{emp.job_title || '-'}</td>
                      <td className="px-5 py-4 text-slate-600">{emp.phone || '-'}</td>
                      <td className="px-5 py-4">
                        <span className="inline-flex items-center gap-1 text-slate-600">
                          <Users className="w-3.5 h-3.5" />
                          {emp.family_members?.length || 0}
                        </span>
                      </td>
                      <td className="px-5 py-4">
                        <Link to={`/employees/${emp.id}`} className="btn-secondary py-1.5 text-xs">
                          <Eye className="w-3.5 h-3.5" /> التفاصيل
                        </Link>
                      </td>
                    </tr>
                  ))}
              {!isLoading && employees.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-slate-400">
                    <Users className="w-10 h-10 mx-auto mb-2 text-slate-200" />
                    لا يوجد موظفون
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-xl max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <h2 className="text-lg font-bold">إضافة موظف جديد</h2>
              <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-slate-600 text-2xl leading-none">&times;</button>
            </div>
            <form
              className="p-6 space-y-4"
              onSubmit={(e) => { e.preventDefault(); create.mutate(form) }}
            >
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">رقم الموظف *</label>
                  <input {...inp('employee_id')} required />
                </div>
                <div>
                  <label className="form-label">رقم الهوية *</label>
                  <input {...inp('national_id')} required />
                </div>
                <div className="col-span-2">
                  <label className="form-label">الاسم الكامل *</label>
                  <input {...inp('full_name')} required />
                </div>
                <div>
                  <label className="form-label">الجنس</label>
                  <select {...inp('gender') as any} className="input-field">
                    <option value="M">ذكر</option>
                    <option value="F">أنثى</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">تاريخ الميلاد *</label>
                  <input type="date" {...inp('date_of_birth')} required />
                </div>
                <div>
                  <label className="form-label">تاريخ التوظيف *</label>
                  <input type="date" {...inp('hire_date')} required />
                </div>
                <div>
                  <label className="form-label">القسم</label>
                  <input {...inp('department')} />
                </div>
                <div>
                  <label className="form-label">المسمى الوظيفي</label>
                  <input {...inp('job_title')} />
                </div>
                <div>
                  <label className="form-label">الجوال</label>
                  <input {...inp('phone')} />
                </div>
                <div>
                  <label className="form-label">البريد الإلكتروني</label>
                  <input type="email" {...inp('email')} />
                </div>
              </div>
              <div className="flex gap-3 pt-2">
                <button type="submit" disabled={create.isPending} className="btn-primary flex-1 justify-center">
                  {create.isPending ? 'جارٍ الحفظ...' : 'حفظ'}
                </button>
                <button type="button" onClick={() => setShowModal(false)} className="btn-secondary flex-1 justify-center">
                  إلغاء
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
