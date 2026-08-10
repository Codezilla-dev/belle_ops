import { CONFIRMATION_STYLES } from './visitStyles'

function Stat({ label, value, tone = 'text-slate-900', hint = null }) {
  return (
    <div className="rounded-lg border border-slate-200 bg-white px-4 py-3">
      <div className={`text-2xl font-semibold ${tone}`}>{value}</div>
      <div className="text-xs uppercase tracking-wide text-slate-500">{label}</div>
      {hint && <div className="mt-0.5 text-[11px] text-emerald-700">{hint}</div>}
    </div>
  )
}

export default function DaySummary({ summary }) {
  return (
    <div className="mb-4 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
      <Stat label="Visits today" value={summary.total} />
      <Stat label="Completed" value={summary.completed} tone="text-emerald-700" />
      <Stat label="Unconfirmed" value={summary.unconfirmed} tone="text-amber-700" />
      <Stat label="Fell through" value={summary.fell_through} tone="text-rose-700" />
      <Stat label="Open slots to fill" value={summary.open_slots} tone="text-indigo-700" />
      <Stat label="At risk, still ahead" value={summary.at_risk} tone="text-amber-700" />
      <Stat
        label="Drive minutes wasted"
        value={summary.drive_wasted_minutes}
        tone="text-rose-700"
        hint={summary.drive_saved_minutes > 0 ? `${summary.drive_saved_minutes} min saved by early notice` : null}
      />
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
