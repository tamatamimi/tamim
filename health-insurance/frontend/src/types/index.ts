export interface Employee {
  id: number
  employee_number: string
  first_name: string
  last_name: string
  full_name: string
  department: string
  phone: string
  email: string
  gender: 'male' | 'female'
  date_of_birth: string
  hire_date: string
  national_id: string
  insurance_class: string
  annual_limit: number
  used_amount: number
  remaining_amount: number
  family_members_count: number
  is_active: boolean
  created_at: string
}

export interface FamilyMember {
  id: number
  employee: number
  name: string
  relation: 'spouse' | 'son' | 'daughter' | 'father' | 'mother'
  gender: 'male' | 'female'
  date_of_birth: string
  national_id: string
  annual_limit: number
  used_amount: number
  remaining_amount: number
}

export interface Claim {
  id: number
  claim_number: string
  employee: number
  employee_name: string
  employee_number: string
  beneficiary_type: 'employee' | 'family'
  family_member?: number
  family_member_name?: string
  claim_type: string
  hospital_name: string
  diagnosis: string
  service_date: string
  invoice_amount: number
  coverage_percent: number
  insurance_amount: number
  employee_amount: number
  approved_amount: number | null
  status: 'pending' | 'approved' | 'rejected' | 'paid'
  rejection_reason: string | null
  notes: string | null
  submitted_at: string
  approved_at: string | null
  paid_at: string | null
  documents: ClaimDocument[]
}

export interface ClaimDocument {
  id: number
  claim: number
  document_type: string
  file_name: string
  file_url: string
  file_size: number
  uploaded_at: string
}

export interface InsuranceSettings {
  id: number
  inpatient_coverage_percent: number
  outpatient_coverage_percent: number
  emergency_coverage_percent: number
  employee_annual_limit: number
  family_member_annual_limit: number
  max_per_claim: number
  policy_number: string
  insurance_company: string
  policy_start_date: string
  policy_end_date: string
}

export interface DashboardStats {
  total_employees: number
  active_employees: number
  total_claims_year: number
  pending_claims: number
  approved_claims: number
  rejected_claims: number
  paid_claims: number
  total_insurance_paid: number
  total_invoices: number
  avg_claim_amount: number
}

export interface ReportSummary {
  year: number
  total_claims: number
  total_invoice_amount: number
  total_insurance_amount: number
  total_employee_amount: number
  by_type: Array<{ claim_type: string; count: number; insurance_amount: number }>
}

export interface MonthlyTrend {
  month: number
  month_name: string
  count: number
  insurance_amount: number
}

export interface EmployeeUtilization {
  employee_id: number
  employee_name: string
  employee_number: string
  department: string
  annual_limit: number
  used_amount: number
  remaining_amount: number
  utilization_percent: number
  claims_count: number
}

export type PaginatedResponse<T> = {
  count: number
  next: string | null
  previous: string | null
  results: T[]
}
