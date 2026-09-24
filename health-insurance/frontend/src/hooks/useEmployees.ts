import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { employeesApi, familyApi } from '@/lib/api'
import toast from 'react-hot-toast'

export const EMPLOYEES_KEY = 'employees'

export function useEmployees(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: [EMPLOYEES_KEY, params],
    queryFn: () => employeesApi.list(params),
  })
}

export function useEmployee(id: number) {
  return useQuery({
    queryKey: [EMPLOYEES_KEY, id],
    queryFn: () => employeesApi.get(id),
    enabled: !!id,
  })
}

export function useEmployeeUsage(id: number, year?: number) {
  return useQuery({
    queryKey: [EMPLOYEES_KEY, id, 'usage', year],
    queryFn: () => employeesApi.getUsage(id, year),
    enabled: !!id,
  })
}

export function useEmployeeClaims(id: number, params?: Record<string, unknown>) {
  return useQuery({
    queryKey: [EMPLOYEES_KEY, id, 'claims', params],
    queryFn: () => employeesApi.getClaims(id, params),
    enabled: !!id,
  })
}

export function useFamilyMembers(employeeId: number) {
  return useQuery({
    queryKey: [EMPLOYEES_KEY, employeeId, 'family'],
    queryFn: () => familyApi.list(employeeId),
    enabled: !!employeeId,
  })
}

export function useCreateEmployee() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: unknown) => employeesApi.create(data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [EMPLOYEES_KEY] })
      toast.success('تم إضافة الموظف بنجاح')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء إضافة الموظف')
    },
  })
}

export function useUpdateEmployee(id: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: unknown) => employeesApi.update(id, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [EMPLOYEES_KEY, id] })
      qc.invalidateQueries({ queryKey: [EMPLOYEES_KEY] })
      toast.success('تم تحديث بيانات الموظف')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء تحديث البيانات')
    },
  })
}

export function useDeleteEmployee() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => employeesApi.delete(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [EMPLOYEES_KEY] })
      toast.success('تم حذف الموظف')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء الحذف')
    },
  })
}

export function useAddFamilyMember(employeeId: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: unknown) => familyApi.create(employeeId, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [EMPLOYEES_KEY, employeeId, 'family'] })
      toast.success('تم إضافة فرد العائلة بنجاح')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء إضافة فرد العائلة')
    },
  })
}
