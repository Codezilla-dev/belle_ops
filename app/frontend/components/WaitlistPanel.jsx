const REASON_LABELS = {
  member_called: 'Called in',
  prior_cancellation: 'Earlier visit fell through',
  clinical_outreach: 'Flagged by clinical',
}

export default function WaitlistPanel({ waitlist, onJumpToSlot }) {
  return (
    <aside className="rounded-lg border border-slate-200 bg-white">
      <div className="border-b border-slate-200 px-4 py-3">
        <h2 className="text-sm font-semibold text-slate-900">Waiting for a visit</h2>
        <p className="text-xs text-slate-500">
          {waitlist.length} member{waitlist.length === 1 ? '' : 's'}, most urgent first
        </p>
      </div>

      {waitlist.length === 0 ? (
        <p className="px-4 py-6 text-sm text-slate-500">Nobody is waiting. Rare and good.</p>
      ) : (
        <ul className="divide-y divide-slate-100">
          {waitlist.map((entry) => (
            <li key={entry.id} className="px-4 py-3">
              <div className="flex items-center gap-2">
                <span className="font-medium text-slate-900">
                  {entry.no_show_risk && <span title={`${entry.prior_no_shows} prior no-shows`}>⚠️ </span>}
                  {entry.member_name}
                </span>
                {entry.clinical_priority === 'high' && (
                  <span className="rounded-full bg-rose-100 px-2 py-0.5 text-[11px] font-medium text-rose-800">
                    Urgent
                  </span>
                )}
              </div>

              <p className="mt-0.5 text-xs text-slate-500">
                {REASON_LABELS[entry.reason] ?? entry.reason} · waiting {entry.days_waiting} days ·
                prefers {entry.preferred_timeframe}
              </p>

              {entry.placement ? (
                <button
                  type="button"
                  onClick={() => onJumpToSlot(entry.placement.slot_id)}
                  className="mt-1.5 w-full rounded-md bg-indigo-50 px-2 py-1 text-left text-xs font-medium text-indigo-800 hover:bg-indigo-100"
                >
                  Fits {entry.placement.technician_name} at {entry.placement.time_label} →
                </button>
              ) : (
                <p className="mt-1.5 text-xs text-slate-400">No slot open today</p>
              )}
            </li>
          ))}
        </ul>
      )}
    </aside>
  )
}
