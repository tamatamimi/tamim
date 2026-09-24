import axios from 'axios'

export const api = axios.create({ baseURL: '/api' })

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  },
)

// ── Types ────────────────────────────────────────────────────────────────────

export interface InsuranceSettings {
  id: number
  name: string
  inpatient_pct: number
  outpatient_pct: number
  employee_annual_limit: number
  family_annual_limit: number
  max_per_claim: number
  is_active: boolean
}

export interface FamilyMember {
  id: number
  employee_id: number
  full_name: string
  national_id: string
  relation: string
  date_of_birth: string
  is_active: boolean
  annual_used?: number
  annual_remaining?: number
}

export interface Employee {
  id: number
  employee_id: string
  full_name: string
  national_id: string
  gender: 'M' | 'F'
  date_of_birth: string
  hire_date: string
  department: string
  job_title: string
  phone: string
  email: string
  is_active: boolean
  settings_id?: number
  family_members: FamilyMember[]
  annual_used?: number
  annual_remaining?: number
  annual_limit?: number
  usage_pct?: number
  settings?: InsuranceSettings
}

export interface ClaimDocument {
  id: number
  claim_id: number
  document_type: string
  original_filename: string
  file_size: number
  uploaded_at: string
}

export interface Claim {
  id: number
  claim_number: string
  employee_id: number
  employee_name: string
  beneficiary_type: 'employee' | 'family'
  beneficiary_name: string
  family_member_id?: number
  claim_type: 'inpatient' | 'outpatient' | 'emergency'
  claim_date: string
  hospital_name: string
  diagnosis: string
  invoice_amount: number
  coverage_pct: number
  insurance_amount: number
  employee_amount: number
  approved_amount: number
  status: 'pending' | 'approved' | 'partially_approved' | 'rejected' | 'paid'
  notes: string
  rejection_reason: string
  created_at: string
  documents: ClaimDocument[]
}

export interface ReportSummary {
  year: number
  total_employees: number
  total_claims: number
  pending_claims: number
  total_invoice: number
  total_insurance: number
  total_employee_amount: number
  by_type: { claim_type: string; label: string; count: number; total_invoice: number; total_insurance: number }[]
  monthly: { month: number; month_label: string; count: number; total_insurance: number }[]
}

export interface EmployeeReport {
  employee_id: string
  full_name: string
  department: string
  annual_limit: number
  annual_used: number
  annual_remaining: number
  usage_pct: number
  claim_count: number
}

// ── API Functions ─────────────────────────────────────────────────────────────

export const authApi = {
  login: (username: string, password: string) =>
    api.post('/auth/login', { username, password }).then((r) => r.data),
  me: () => api.get('/auth/me').then((r) => r.data),
}

export const employeesApi = {
  list: (q?: string) => api.get('/employees', { params: { q } }).then((r) => r.data),
  get: (id: number, year?: number) => api.get(`/employees/${id}`, { params: { year } }).then((r) => r.data),
  create: (data: Partial<Employee>) => api.post('/employees', data).then((r) => r.data),
  update: (id: number, data: Partial<Employee>) => api.put(`/employees/${id}`, data).then((r) => r.data),
  delete: (id: number) => api.delete(`/employees/${id}`).then((r) => r.data),
  getFamily: (id: number, year?: number) =>
    api.get(`/employees/${id}/family`, { params: { year } }).then((r) => r.data),
}

export const familyApi = {
  create: (data: Partial<FamilyMember>) => api.post('/family', data).then((r) => r.data),
  update: (id: number, data: Partial<FamilyMember>) => api.put(`/family/${id}`, data).then((r) => r.data),
  delete: (id: number) => api.delete(`/family/${id}`).then((r) => r.data),
}

export const claimsApi = {
  list: (params?: Record<string, unknown>) => api.get('/claims', { params }).then((r) => r.data),
  get: (id: number) => api.get(`/claims/${id}`).then((r) => r.data),
  create: (data: Partial<Claim>) => api.post('/claims', data).then((r) => r.data),
  updateStatus: (id: number, data: { status: string; approved_amount?: number; notes?: string; rejection_reason?: string }) =>
    api.put(`/claims/${id}/status`, data).then((r) => r.data),
}

export const documentsApi = {
  upload: (claimId: number, file: File, documentType: string) => {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('document_type', documentType)
    return api.post(`/documents/upload/${claimId}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }).then((r) => r.data)
  },
  delete: (id: number) => api.delete(`/documents/${id}`).then((r) => r.data),
}

export const settingsApi = {
  list: () => api.get('/settings').then((r) => r.data),
  getActive: () => api.get('/settings/active').then((r) => r.data),
  create: (data: Partial<InsuranceSettings>) => api.post('/settings', data).then((r) => r.data),
  update: (id: number, data: Partial<InsuranceSettings>) => api.put(`/settings/${id}`, data).then((r) => r.data),
}

export const reportsApi = {
  summary: (year?: number) => api.get('/reports/summary', { params: { year } }).then((r) => r.data),
  employees: (year?: number) => api.get('/reports/employees', { params: { year } }).then((r) => r.data),
}
