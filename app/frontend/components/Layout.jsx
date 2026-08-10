import { Link, usePage } from '@inertiajs/react'

function NavLink({ href, children }) {
  const { url } = usePage()
  const active = url === href || (href !== '/' && url.startsWith(href))

  return (
    <Link
      href={href}
      className={`rounded-md px-3 py-1.5 text-sm font-medium transition ${
        active ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-300 hover:text-white'
      }`}
    >
      {children}
    </Link>
  )
}

function FlashToast() {
  const { flash } = usePage().props
  const message = flash?.notice ?? flash?.alert
  if (!message) return null

  return (
    <div
      className={`mb-4 rounded-lg border px-4 py-2.5 text-sm ${
        flash.alert
          ? 'border-rose-200 bg-rose-50 text-rose-900'
          : 'border-emerald-200 bg-emerald-50 text-emerald-900'
      }`}
    >
      {message}
    </div>
  )
}

export default function Layout({ children }) {
  return (
    <div className="min-h-screen bg-slate-100 text-slate-900">
      <header className="bg-slate-900">
        <div className="mx-auto flex max-w-none items-center gap-6 px-6 py-3">
          <span className="text-base font-semibold tracking-tight text-white">
            Belle <span className="font-normal text-slate-400">Ops</span>
          </span>
          <nav className="flex items-center gap-1">
            <NavLink href="/">Today&apos;s schedule</NavLink>
            <NavLink href="/patients">Members</NavLink>
          </nav>
        </div>
      </header>

      <main className="mx-auto max-w-none px-6 py-6">
        <FlashToast />
        {children}
      </main>
    </div>
  )
}
