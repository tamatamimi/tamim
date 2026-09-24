import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ShieldPlus } from 'lucide-react'
import toast from 'react-hot-toast'
import { authApi } from '../lib/api'

export default function Login() {
  const navigate = useNavigate()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      const data = await authApi.login(username, password)
      localStorage.setItem('token', data.access_token)
      navigate('/')
    } catch {
      toast.error('اسم المستخدم أو كلمة المرور غير صحيحة')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-blue-900 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl p-8 w-full max-w-md">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <ShieldPlus className="w-9 h-9 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-slate-900">نظام التأمين الصحي</h1>
          <p className="text-slate-500 mt-1 text-sm">سجّل دخولك للمتابعة</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="form-label">اسم المستخدم</label>
            <input
              type="text"
              className="input-field"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="admin"
              required
            />
          </div>
          <div>
            <label className="form-label">كلمة المرور</label>
            <input
              type="password"
              className="input-field"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>
          <button type="submit" disabled={loading} className="btn-primary w-full justify-center py-3 mt-2">
            {loading ? 'جارٍ تسجيل الدخول...' : 'تسجيل الدخول'}
          </button>
        </form>

        <p className="text-center text-sm text-slate-400 mt-6">
          المستخدم الافتراضي: <code className="bg-slate-100 px-1 rounded">admin</code> /
          <code className="bg-slate-100 px-1 rounded mr-1">admin123</code>
        </p>
      </div>
    </div>
  )
}
