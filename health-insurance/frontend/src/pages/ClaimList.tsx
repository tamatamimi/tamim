import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Search, Plus, Filter } from 'lucide-react'
import { claimsApi, Claim } from '../lib/api'
import { formatCurrency, STATUS_LABELS, CLAIM_TYPE_LABELS, getStatusBadge, currentYear } from '../lib/utils'

const STATUS_OPTIONS = ['', 'pending', 'approved', 'partially_approved', 'rejected', 'paid']
const TYPE_OPTIONS = ['', 'inpatient', 'outpatient', 'emergency']

export default function ClaimList() {
  const [q, setQ] = useState('')
  const [status, setStatus] = useState('')
  const [claimType, setClaimType] = useState('')
  const [year, setYear] = useState<number | ''>('')

  const { data: claims = [], isLoading } = useQuery({
    queryKey: ['claims', q, status, claimType, year],
    queryFn: () => claimsApi.list({ q: q || undefined, status: status || undefined, claim_type: claimType || undefined, year: year || undefined }),
  })

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">المطالبات</h1>
          <p className="text-sm text-slate-500 mt-0.5">{claims.length} مطالبة</p>
        </div>
        <Link to="/claims/new" className="btn-primary">
          <Plus className="w-4 h-4" /> مطالبة جديدة
        </Link>
      </div>

      {/* Filters */}
      <div className="card p-4">
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
          <div className="relative sm:col-span-2">
            <Search className="w-4 h-4 absolute top-1/2 -translate-y-1/2 right-3 text-slate-400" />
            <input className="input-field pr-9" placeholder="بحث برقم المطالبة أو الموظف..." value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          <select className="input-field" value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="">كل الحالات</option>
            {STATUS_OPTIONS.filter(Boolean).map((s) => <option key={s} value={s}>{STATUS_LABELS[s]}</option>)}
          </select>
          <select className="input-field" value={claimType} onChange={(e) => setClaimType(e.target.value)}>
            <option value="">كل الأنواع</option>
            {TYPE_OPTIONS.filter(Boolean).map((t) => <option key={t} value={t}>{CLAIM_TYPE_LABELS[t]}</option>)}
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-50 border-b border-slate-100">
              <tr>
                {['رقم المطالبة', 'الموظف', 'المستفيد', 'النوع', 'التاريخ', 'الفاتورة', 'التغطية', 'التأمين', 'تحمل الموظف', 'الحالة'].map((h) => (
                  <th key={h} className="text-right px-4 py-3 text-xs font-semibold text-slate-500">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {isLoading
                ? Array.from({ length: 5 }).map((_, i) => (
                    <tr key={i}>{Array.from({ length: 10 }).map((_, j) => (
                      <td key={j} className="px-4 py-3"><div className="h-4 bg-slate-100 rounded animate-pulse" /></td>
                    ))}</tr>
                  ))
                : claims.map((c: Claim) => (
                    <tr key={c.id} className="hover:bg-blue-50/30 transition-colors">
                      <td className="px-4 py-3">
                        <Link to={`/claims/${c.id}`} className="text-blue-600 font-mono hover:underline text-xs">{c.claim_number}</Link>
                      </td>
                      <td className="px-4 py-3 font-medium">{c.employee_name}</td>
                      <td className="px-4 py-3 text-slate-600">{c.beneficiary_name}</td>
                      <td className="px-4 py-3">
                        <span className={`text-xs font-medium px-2 py-1 rounded-md ${c.claim_type === 'inpatient' ? 'bg-blue-100 text-blue-700' : 'bg-amber-100 text-amber-700'}`}>
                          {CLAIM_TYPE_LABELS[c.claim_type]}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-slate-500">{c.claim_date}</td>
                      <td className="px-4 py-3">{formatCurrency(c.invoice_amount)}</td>
                      <td className={`px-4 py-3 font-bold ${c.claim_type === 'inpatient' ? 'text-emerald-600' : 'text-amber-600'}`}>{c.coverage_pct}%</td>
                      <td className="px-4 py-3 text-emerald-600 font-semibold">{formatCurrency(c.insurance_amount)}</td>
                      <td className="px-4 py-3 text-red-500">{formatCurrency(c.employee_amount)}</td>
                      <td className="px-4 py-3">
                        <span className={getStatusBadge(c.status)}>{STATUS_LABELS[c.status]}</span>
                      </td>
                    </tr>
                  ))}
              {!isLoading && claims.length === 0 && (
                <tr><td colSpan={10} className="text-center py-10 text-slate-400">لا توجد مطالبات</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
