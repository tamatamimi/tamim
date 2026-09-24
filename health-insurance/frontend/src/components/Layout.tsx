import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, Users, FileText, BarChart3, Settings,
  ShieldPlus, LogOut, PlusCircle, Menu, X
} from 'lucide-react'
import { useState } from 'react'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'لوحة التحكم', exact: true },
  { to: '/employees', icon: Users, label: 'الموظفون' },
  { to: '/claims', icon: FileText, label: 'المطالبات' },
  { to: '/claims/new', icon: PlusCircle, label: 'مطالبة جديدة' },
  { to: '/reports', icon: BarChart3, label: 'التقارير' },
  { to: '/settings', icon: Settings, label: 'الإعدادات' },
]

export default function Layout() {
  const navigate = useNavigate()
  const [sidebarOpen, setSidebarOpen] = useState(true)

  const handleLogout = () => {
    localStorage.removeItem('token')
    navigate('/login')
  }

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50">
      {/* Sidebar */}
      <aside
        className={`${sidebarOpen ? 'w-60' : 'w-16'} bg-slate-900 flex flex-col transition-all duration-300 shrink-0`}
      >
        {/* Brand */}
        <div className="flex items-center gap-3 px-4 py-5 border-b border-slate-700">
          <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center shrink-0">
            <ShieldPlus className="w-5 h-5 text-white" />
          </div>
          {sidebarOpen && (
            <div>
              <div className="text-white font-bold text-sm leading-tight">نظام التأمين</div>
              <div className="text-slate-400 text-xs">الصحي</div>
            </div>
          )}
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="mr-auto text-slate-400 hover:text-white"
          >
            {sidebarOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-2 py-4 space-y-1 overflow-y-auto">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.exact}
              className={({ isActive }) =>
                `sidebar-nav-link ${isActive ? 'active' : ''}`
              }
              title={!sidebarOpen ? item.label : undefined}
            >
              <item.icon className="w-5 h-5 shrink-0" />
              {sidebarOpen && <span>{item.label}</span>}
            </NavLink>
          ))}
        </nav>

        {/* Logout */}
        <div className="p-2 border-t border-slate-700">
          <button
            onClick={handleLogout}
            className="sidebar-nav-link w-full text-red-400 hover:text-red-300 hover:bg-red-900/20"
          >
            <LogOut className="w-5 h-5 shrink-0" />
            {sidebarOpen && <span>تسجيل الخروج</span>}
          </button>
        </div>
      </aside>

      {/* Main */}
      <main className="flex-1 overflow-y-auto">
        <div className="p-6">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
