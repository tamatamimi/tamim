import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { claimsApi } from '@/lib/api'
import toast from 'react-hot-toast'

export const CLAIMS_KEY = 'claims'

export function useClaims(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: [CLAIMS_KEY, params],
    queryFn: () => claimsApi.list(params),
  })
}

export function useClaim(id: number) {
  return useQuery({
    queryKey: [CLAIMS_KEY, id],
    queryFn: () => claimsApi.get(id),
    enabled: !!id,
  })
}

export function useCreateClaim() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: FormData) => claimsApi.create(data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [CLAIMS_KEY] })
      toast.success('تم تقديم المطالبة بنجاح')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء تقديم المطالبة')
    },
  })
}

export function useApproveClaim(id: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: { approved_amount: number; notes?: string }) =>
      claimsApi.approve(id, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [CLAIMS_KEY, id] })
      qc.invalidateQueries({ queryKey: [CLAIMS_KEY] })
      toast.success('تمت الموافقة على المطالبة')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء الموافقة على المطالبة')
    },
  })
}

export function useRejectClaim(id: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: { reason: string }) => claimsApi.reject(id, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [CLAIMS_KEY, id] })
      qc.invalidateQueries({ queryKey: [CLAIMS_KEY] })
      toast.success('تم رفض المطالبة')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء رفض المطالبة')
    },
  })
}

export function useMarkClaimPaid(id: number) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: () => claimsApi.markPaid(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [CLAIMS_KEY, id] })
      qc.invalidateQueries({ queryKey: [CLAIMS_KEY] })
      toast.success('تم تسجيل الدفع بنجاح')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء تسجيل الدفع')
    },
  })
}
