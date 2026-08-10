import { CONFIRMATION_STYLES } from './visitStyles'

function Stat({ label, value, tone = 'text-slate-900' }) {
  return (
    <div className="rounded-lg border border-slate-200 bg-white px-4 py-3">
      <div className={`text-2xl font-semibold ${tone}`}>{value}</div>
      <div className="text-xs uppercase tracking-wide text-slate-500">{label}</div>
    </div>
  )
}

export default function DaySummary({ summary }) {
  return (
    <div className="mb-4 grid grid-cols-2 gap-3 sm:grid-cols-5">
      <Stat label="Visits today" value={summary.total} />
      <Stat label="Completed" value={summary.completed} tone="text-emerald-700" />
      <Stat label="Fell through" value={summary.fell_through} tone="text-rose-700" />
      <Stat label="Unconfirmed" value={summary.unconfirmed} tone="text-amber-700" />
      <Stat label="No-show risk" value={summary.at_risk} tone="text-amber-700" />
    </div>
  )
}

export function Legend() {
  return (
    <div className="mt-3 flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-slate-600">
      {Object.entries(CONFIRMATION_STYLES).map(([key, style]) => (
        <span key={key} className="flex items-center gap-1.5">
          <span className={`h-2.5 w-2.5 rounded-full ${style.dot}`} />
          {style.label}
        </span>
      ))}
      <span className="flex items-center gap-1.5">⚠️ 2+ prior no-shows</span>
      <span className="flex items-center gap-1.5 line-through decoration-slate-500">Fell through</span>
    </div>
  )
}
