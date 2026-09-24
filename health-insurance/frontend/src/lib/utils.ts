import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export const cn = (...inputs: ClassValue[]) => twMerge(clsx(inputs))

export const formatCurrency = (v: number | string) =>
  `${Number(v).toLocaleString('ar-SA', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ريال`

export const formatNumber = (v: number | string) =>
  Number(v).toLocaleString('ar-SA', { minimumFractionDigits: 0, maximumFractionDigits: 2 })

export const formatDate = (d: string) =>
  new Date(d).toLocaleDateString('ar-SA', { year: 'numeric', month: 'long', day: 'numeric' })

export const STATUS_LABELS: Record<string, string> = {
  pending: 'قيد المراجعة',
  approved: 'مقبولة',
  partially_approved: 'مقبولة جزئياً',
  rejected: 'مرفوضة',
  paid: 'مدفوعة',
}

export const CLAIM_TYPE_LABELS: Record<string, string> = {
  inpatient: 'مريض داخلي',
  outpatient: 'عيادات خارجية',
  emergency: 'طوارئ',
}

export const RELATION_LABELS: Record<string, string> = {
  spouse: 'زوج/زوجة',
  son: 'ابن',
  daughter: 'ابنة',
  father: 'والد',
  mother: 'والدة',
  other: 'أخرى',
}

export const DOCUMENT_TYPE_LABELS: Record<string, string> = {
  invoice: 'فاتورة طبية',
  doctor_request: 'طلب طبيب',
  prescription: 'وصفة طبية',
  lab_result: 'نتيجة مختبر',
  xray: 'أشعة',
  discharge_summary: 'ملخص خروج',
  other: 'أخرى',
}

export const getStatusBadge = (status: string) => {
  const map: Record<string, string> = {
    pending: 'badge badge-pending',
    approved: 'badge badge-approved',
    partially_approved: 'badge badge-partially_approved',
    rejected: 'badge badge-rejected',
    paid: 'badge badge-paid',
  }
  return map[status] || 'badge badge-pending'
}

export const currentYear = () => new Date().getFullYear()
