import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Save, Shield, AlertTriangle } from 'lucide-react'
import toast from 'react-hot-toast'
import { settingsApi } from '../lib/api'
import { formatCurrency } from '../lib/utils'

export default function Settings() {
  const qc = useQueryClient()

  const { data: settings, isLoading } = useQuery({
    queryKey: ['settings-active'],
    queryFn: () => settingsApi.getActive(),
  })

  const [form, setForm] = useState({
    inpatient_pct: 90,
    outpatient_pct: 70,
    employee_annual_limit: 50000,
    family_annual_limit: 30000,
    max_per_claim: 15000,
    is_active: true,
  })

  useEffect(() => {
    if (settings) {
      setForm({
        inpatient_pct: settings.inpatient_pct,
        outpatient_pct: settings.outpatient_pct,
        employee_annual_limit: settings.employee_annual_limit,
        family_annual_limit: settings.family_annual_limit,
        max_per_claim: settings.max_per_claim,
        is_active: settings.is_active,
      })
    }
  }, [settings])

  const updateSettings = useMutation({
    mutationFn: () => settingsApi.update(settings!.id, form),
    onSuccess: () => {
      toast.success('تم حفظ إعدادات التأمين')
      qc.invalidateQueries({ queryKey: ['settings-active'] })
      qc.invalidateQueries({ queryKey: ['settings'] })
    },
    onError: (e: any) => toast.error(e.response?.data?.detail || 'حدث خطأ أثناء الحفظ'),
  })

  const f = (field: string, numeric = true) => ({
    value: (form as any)[field],
    onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
      setForm((p) => ({ ...p, [field]: numeric ? Number(e.target.value) : e.target.value })),
  })

  if (isLoading) return <div className="p-8 text-center text-slate-400">جارٍ التحميل...</div>

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">إعدادات التأمين</h1>
        <p className="text-sm text-slate-500 mt-0.5">تكوين سياسة التأمين الصحي للموظفين والعائلات</p>
      </div>

      {/* Coverage Percentages */}
      <div className="card p-6 space-y-5">
        <div className="flex items-center gap-2 pb-3 border-b border-slate-100">
          <Shield className="w-5 h-5 text-blue-500" />
          <h3 className="font-semibold text-slate-800">نسب التغطية التأمينية</h3>
        </div>

        <div className="grid grid-cols-2 gap-6">
          <div>
            <label className="form-label">تغطية المريض الداخلي (رقود)</label>
            <div className="relative">
              <input
                type="number" min="1" max="100" step="1"
                className="input-field pl-8"
                {...f('inpatient_pct')}
              />
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-bold">%</span>
            </div>
            <div className="mt-2 h-2 bg-slate-100 rounded-full overflow-hidden">
              <div className="h-full bg-emerald-500 rounded-full transition-all" style={{ width: `${form.inpatient_pct}%` }} />
            </div>
            <p className="text-xs text-slate-400 mt-1">الموظف يتحمل {100 - form.inpatient_pct}%</p>
          </div>

          <div>
            <label className="form-label">تغطية الطوارئ والعيادات</label>
            <div className="relative">
              <input
                type="number" min="1" max="100" step="1"
                className="input-field pl-8"
                {...f('outpatient_pct')}
              />
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-bold">%</span>
            </div>
            <div className="mt-2 h-2 bg-slate-100 rounded-full overflow-hidden">
              <div className="h-full bg-amber-500 rounded-full transition-all" style={{ width: `${form.outpatient_pct}%` }} />
            </div>
            <p className="text-xs text-slate-400 mt-1">الموظف يتحمل {100 - form.outpatient_pct}%</p>
          </div>
        </div>

        {/* Visual Preview */}
        <div className="bg-slate-50 rounded-xl p-4">
          <p className="text-xs font-semibold text-slate-500 mb-3 uppercase tracking-wider">معاينة لمطالبة بقيمة 10,000 ريال</p>
          <div className="grid grid-cols-2 gap-4">
            {[
              { label: 'مريض داخلي', pct: form.inpatient_pct, color: 'emerald' },
              { label: 'طوارئ / عيادات', pct: form.outpatient_pct, color: 'amber' },
            ].map((t) => (
              <div key={t.label} className={`bg-${t.color}-50 border border-${t.color}-200 rounded-lg p-3 text-center`}>
                <p className="text-xs text-slate-500">{t.label}</p>
                <p className={`text-xl font-bold text-${t.color}-600 mt-1`}>{formatCurrency(10000 * t.pct / 100)}</p>
                <p className="text-xs text-slate-400">يدفعها التأمين ({t.pct}%)</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Annual Limits */}
      <div className="card p-6 space-y-5">
        <h3 className="font-semibold text-slate-800 pb-3 border-b border-slate-100">السقوف السنوية</h3>

        <div className="space-y-4">
          <div>
            <label className="form-label">السقف السنوي للموظف (ريال)</label>
            <input type="number" min="1000" step="1000" className="input-field" {...f('employee_annual_limit')} />
            <p className="text-xs text-slate-400 mt-1">الحد الأقصى الذي تغطيه الشركة للموظف سنوياً</p>
          </div>

          <div>
            <label className="form-label">السقف السنوي لكل فرد من العائلة (ريال)</label>
            <input type="number" min="1000" step="1000" className="input-field" {...f('family_annual_limit')} />
            <p className="text-xs text-slate-400 mt-1">الحد الأقصى لكل فرد على حدة (زوجة، أبناء)</p>
          </div>

          <div>
            <label className="form-label">الحد الأقصى للمطالبة الواحدة (ريال)</label>
            <input type="number" min="1000" step="1000" className="input-field" {...f('max_per_claim')} />
            <p className="text-xs text-slate-400 mt-1">لا تُغطى قيمة الفاتورة التي تتجاوز هذا المبلغ</p>
          </div>
        </div>

        {/* Summary */}
        <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <p className="text-xs font-semibold text-blue-700 mb-2">ملخص السياسة الحالية</p>
          <ul className="text-sm text-slate-600 space-y-1">
            <li>• سقف الموظف السنوي: <strong>{formatCurrency(form.employee_annual_limit)}</strong></li>
            <li>• سقف فرد العائلة: <strong>{formatCurrency(form.family_annual_limit)}</strong></li>
            <li>• أقصى مطالبة واحدة: <strong>{formatCurrency(form.max_per_claim)}</strong></li>
          </ul>
        </div>
      </div>

      {/* Warning */}
      <div className="flex items-start gap-3 bg-amber-50 border border-amber-200 rounded-xl p-4 text-sm text-amber-800">
        <AlertTriangle className="w-5 h-5 shrink-0 mt-0.5 text-amber-500" />
        <p>تغيير هذه الإعدادات سيؤثر على المطالبات الجديدة فقط. المطالبات السابقة المحسوبة لن تتغير.</p>
      </div>

      <div className="flex justify-end">
        <button
          onClick={() => updateSettings.mutate()}
          disabled={updateSettings.isPending || !settings}
          className="btn-primary px-8 py-2.5"
        >
          <Save className="w-4 h-4" />
          {updateSettings.isPending ? 'جارٍ الحفظ...' : 'حفظ الإعدادات'}
        </button>
      </div>
    </div>
  )
}
