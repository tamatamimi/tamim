import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Users, FileText, Clock, TrendingUp, ArrowLeft } from 'lucide-react'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from 'recharts'
import { reportsApi, claimsApi } from '../lib/api'
import { formatCurrency, STATUS_LABELS, getStatusBadge, CLAIM_TYPE_LABELS, currentYear } from '../lib/utils'

const PIE_COLORS = ['#3b82f6', '#10b981', '#f59e0b']

export default function Dashboard() {
  const year = currentYear()
  const { data: summary } = useQuery({ queryKey: ['summary', year], queryFn: () => reportsApi.summary(year) })
  const { data: claims = [] } = useQuery({ queryKey: ['claims-recent'], queryFn: () => claimsApi.list({ limit: 8 }) })

  const statCards = [
    { label: 'الموظفون النشطون', value: summary?.total_employees ?? '-', icon: Users, color: 'bg-blue-500' },
    { label: `مطالبات ${year}`, value: summary?.total_claims ?? '-', icon: FileText, color: 'bg-emerald-500' },
    { label: 'قيد المراجعة', value: summary?.pending_claims ?? '-', icon: Clock, color: 'bg-amber-500' },
    {
      label: 'إجمالي التأمين المصروف',
      value: summary ? formatCurrency(summary.total_insurance) : '-',
      icon: TrendingUp,
      color: 'bg-purple-500',
      wide: true,
    },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">لوحة التحكم</h1>
        <p className="text-slate-500 text-sm mt-1">نظرة عامة على التأمين الصحي — {year}</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((s) => (
          <div key={s.label} className="stat-card flex items-center gap-4">
            <div className={`${s.color} w-12 h-12 rounded-xl flex items-center justify-center shrink-0`}>
              <s.icon className="w-6 h-6 text-white" />
            </div>
            <div>
              <p className="text-sm text-slate-500">{s.label}</p>
              <p className="text-xl font-bold text-slate-900 mt-0.5">{s.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Financial Summary */}
      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="card p-5 text-center">
            <p className="text-sm text-slate-500">إجمالي الفواتير</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{formatCurrency(summary.total_invoice)}</p>
          </div>
          <div className="card p-5 text-center border-emerald-200">
            <p className="text-sm text-slate-500">تغطية التأمين</p>
            <p className="text-2xl font-bold text-emerald-600 mt-1">{formatCurrency(summary.total_insurance)}</p>
          </div>
          <div className="card p-5 text-center border-red-100">
            <p className="text-sm text-slate-500">تحمّل الموظفون</p>
            <p className="text-2xl font-bold text-red-500 mt-1">{formatCurrency(summary.total_employee_amount)}</p>
          </div>
        </div>
      )}

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Monthly Bar Chart */}
        {summary?.monthly && summary.monthly.length > 0 && (
          <div className="card p-6">
            <h3 className="font-semibold text-slate-800 mb-4">التأمين المصروف شهرياً (ريال)</h3>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={summary.monthly}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="month_label" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => formatCurrency(v)} />
                <Bar dataKey="total_insurance" fill="#3b82f6" radius={[4, 4, 0, 0]} name="التأمين" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* By Type Pie */}
        {summary?.by_type && summary.by_type.length > 0 && (
          <div className="card p-6">
            <h3 className="font-semibold text-slate-800 mb-4">توزيع المطالبات حسب النوع</h3>
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie
                  data={summary.by_type}
                  dataKey="count"
                  nameKey="label"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label={({ label, percent }) => `${label} (${(percent * 100).toFixed(0)}%)`}
                >
                  {summary.by_type.map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>

      {/* Recent Claims */}
      <div className="card">
        <div className="flex items-center justify-between p-5 border-b border-slate-100">
          <h3 className="font-semibold text-slate-800">آخر المطالبات</h3>
          <Link to="/claims" className="text-blue-600 text-sm hover:underline flex items-center gap-1">
            عرض الكل <ArrowLeft className="w-4 h-4" />
          </Link>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr>
                {['رقم المطالبة', 'الموظف', 'النوع', 'الفاتورة', 'التأمين', 'الحالة'].map((h) => (
                  <th key={h} className="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {claims.map((c: any) => (
                <tr key={c.id} className="hover:bg-slate-50 transition-colors">
                  <td className="px-4 py-3">
                    <Link to={`/claims/${c.id}`} className="text-blue-600 font-mono hover:underline">{c.claim_number}</Link>
                  </td>
                  <td className="px-4 py-3 font-medium">{c.employee_name}</td>
                  <td className="px-4 py-3 text-slate-600">{CLAIM_TYPE_LABELS[c.claim_type]}</td>
                  <td className="px-4 py-3">{formatCurrency(c.invoice_amount)}</td>
                  <td className="px-4 py-3 text-emerald-600 font-semibold">{formatCurrency(c.insurance_amount)}</td>
                  <td className="px-4 py-3">
                    <span className={getStatusBadge(c.status)}>{STATUS_LABELS[c.status]}</span>
                  </td>
                </tr>
              ))}
              {claims.length === 0 && (
                <tr><td colSpan={6} className="text-center py-8 text-slate-400">لا توجد مطالبات بعد</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
