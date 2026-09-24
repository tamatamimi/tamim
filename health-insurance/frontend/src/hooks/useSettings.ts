import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { settingsApi } from '@/lib/api'
import toast from 'react-hot-toast'

export const SETTINGS_KEY = 'settings'

export function useSettings() {
  return useQuery({
    queryKey: [SETTINGS_KEY],
    queryFn: () => settingsApi.get(),
  })
}

export function useUpdateSettings() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: unknown) => settingsApi.update(data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [SETTINGS_KEY] })
      toast.success('تم حفظ الإعدادات بنجاح')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء حفظ الإعدادات')
    },
  })
}
