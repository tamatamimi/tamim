import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  LineChart, Line, Legend,
} from 'recharts'
import { reportsApi } from '../lib/api'
import { formatCurrency, currentYear } from '../lib/utils'

const YEARS = [0, 1, 2, 3].map((i) => currentYear() - i)

export default function Reports() {
  const [year, setYear] = useState(currentYear())

  const { data: summary, isLoading: summaryLoading } = useQuery({
    queryKey: ['summary', year], queryFn: () => reportsApi.summary(year),
  })
  const { data: empReport = [], isLoading: empLoading } = useQuery({
    queryKey: ['emp-report', year], queryFn: () => reportsApi.employees(year),
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">التقارير والإحصاءات</h1>
          <p className="text-sm text-slate-500 mt-0.5">تحليل استخدام التأمين الصحي</p>
        </div>
        <select className="input-field w-28" value={year} onChange={(e) => setYear(Number(e.target.value))}>
          {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
        </select>
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'إجمالي المطالبات', value: summary.total_claims, color: 'text-blue-600' },
            { label: 'إجمالي الفواتير', value: formatCurrency(summary.total_invoice), color: 'text-slate-800' },
            { label: 'تغطية التأمين', value: formatCurrency(summary.total_insurance), color: 'text-emerald-600' },
            { label: 'تحمّل الموظفون', value: formatCurrency(summary.total_employee_amount), color: 'text-red-500' },
          ].map((s) => (
            <div key={s.label} className="card p-4 text-center">
              <p className="text-xs text-slate-400 mb-1">{s.label}</p>
              <p className={`text-xl font-bold ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>
      )}

      {/* By Type */}
      {summary?.by_type && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {summary.by_type.map((t) => (
            <div key={t.claim_type} className="card p-5">
              <div className="flex items-center gap-2 mb-3">
                <span className={`text-xs font-bold px-2 py-1 rounded-md ${t.claim_type === 'inpatient' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'}`}>
                  {t.claim_type === 'inpatient' ? '90%' : '70%'}
                </span>
                <span className="font-semibold text-sm">{t.label}</span>
              </div>
              <div className="space-y-1 text-sm">
                <div className="flex justify-between"><span className="text-slate-400">عدد المطالبات</span><span className="font-bold">{t.count}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">إجمالي الفواتير</span><span className="font-medium">{formatCurrency(t.total_invoice)}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">التأمين المصروف</span><span className="font-bold text-emerald-600">{formatCurrency(t.total_insurance)}</span></div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Charts */}
      {summary?.monthly && summary.monthly.length > 0 && (
        <div className="card p-6">
          <h3 className="font-semibold text-slate-800 mb-4">التأمين المصروف شهرياً</h3>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={summary.monthly}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="month_label" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip formatter={(v: number) => formatCurrency(v)} />
              <Bar dataKey="total_insurance" fill="#3b82f6" radius={[4, 4, 0, 0]} name="التأمين" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Employee Report Table */}
      <div className="card overflow-hidden">
        <div className="p-5 border-b border-slate-100">
          <h3 className="font-semibold text-slate-800">استهلاك كل موظف — {year}</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr>
                {['الموظف', 'القسم', 'السقف السنوي', 'المستخدم', 'المتبقي', 'نسبة الاستخدام', 'عدد المطالبات'].map((h) => (
                  <th key={h} className="text-right px-5 py-3 text-xs font-semibold text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {empLoading ? (
                Array.from({ length: 4 }).map((_, i) => (
                  <tr key={i}>{Array.from({ length: 7 }).map((_, j) => (
                    <td key={j} className="px-5 py-4"><div className="h-4 bg-slate-100 rounded animate-pulse" /></td>
                  ))}</tr>
                ))
              ) : empReport.map((r: any) => {
                const pct = Math.min(Number(r.usage_pct), 100)
                return (
                  <tr key={r.employee_id} className="hover:bg-slate-50">
                    <td className="px-5 py-4 font-semibold">{r.full_name}</td>
                    <td className="px-5 py-4 text-slate-500">{r.department || '-'}</td>
                    <td className="px-5 py-4">{formatCurrency(r.annual_limit)}</td>
                    <td className="px-5 py-4 text-emerald-600 font-semibold">{formatCurrency(r.annual_used)}</td>
                    <td className={`px-5 py-4 font-semibold ${r.annual_remaining === 0 ? 'text-red-500' : 'text-slate-700'}`}>{formatCurrency(r.annual_remaining)}</td>
                    <td className="px-5 py-4" style={{ minWidth: 180 }}>
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-2 bg-slate-100 rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full ${pct > 80 ? 'bg-red-500' : pct > 50 ? 'bg-amber-500' : 'bg-emerald-500'}`}
                            style={{ width: `${pct}%` }}
                          />
                        </div>
                        <span className="text-xs text-slate-500 w-10 text-left">{pct.toFixed(1)}%</span>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-center">{r.claim_count}</td>
                  </tr>
                )
              })}
              {!empLoading && empReport.length === 0 && (
                <tr><td colSpan={7} className="text-center py-8 text-slate-400">لا يوجد بيانات</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
