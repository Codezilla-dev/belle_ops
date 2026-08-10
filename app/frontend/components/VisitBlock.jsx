import { confirmationStyle } from './visitStyles'

export default function VisitBlock({ visit, pxPerMinute, lanePx, onSelect }) {
  const style = confirmationStyle(visit.confirmation_status)
  const fellThrough = visit.status === 'cancelled' || visit.status === 'no_show'

  return (
    <button
      type="button"
      onClick={() => onSelect(visit)}
      title={`${visit.member_name} · ${visit.time_label}`}
      style={{
        left: visit.offset_minutes * pxPerMinute,
        width: Math.max(visit.duration_minutes * pxPerMinute - 3, 34),
        top: visit.lane * lanePx + 4,
        height: lanePx - 8,
      }}
      className={`absolute overflow-hidden rounded-md border px-1.5 py-1 text-left text-[11px] leading-tight
        ${style.block}
        ${fellThrough ? 'opacity-55 line-through decoration-slate-500/60' : ''}
        ${visit.past && !fellThrough ? 'opacity-70' : ''}
        hover:z-20 hover:ring-2 hover:ring-slate-900/30 focus:z-20 focus:outline-none focus:ring-2 focus:ring-slate-900/40`}
    >
      <span className="block truncate font-semibold">
        {visit.no_show_risk && (
          <span title={`${visit.prior_no_shows} prior no-shows`} className="no-underline">
            ⚠️{' '}
          </span>
        )}
        {visit.member_name}
      </span>
      <span className="block truncate opacity-75">{visit.time_label.split(' – ')[0]}</span>
    </button>
  )
}
