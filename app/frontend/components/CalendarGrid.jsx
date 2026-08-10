import VisitBlock from './VisitBlock'
import OpenSlotBlock from './OpenSlotBlock'

const PX_PER_MINUTE = 2.1
const NAME_COLUMN_PX = 190
const ROW_LANE_PX = 62

export default function CalendarGrid({
  hours,
  minutesInDay,
  technicians,
  nowOffsetMinutes,
  nowLabel,
  onSelectVisit,
  onSelectSlot,
  highlightedSlotId,
  renderRowFooter,
}) {
  const trackWidth = minutesInDay * PX_PER_MINUTE

  return (
    <div className="overflow-x-auto rounded-lg border border-slate-200 bg-white">
      <div style={{ minWidth: NAME_COLUMN_PX + trackWidth }}>
        {/* Hour ruler */}
        <div className="sticky top-0 z-30 flex border-b border-slate-200 bg-slate-50">
          <div
            className="shrink-0 border-r border-slate-200 px-3 py-2 text-xs font-semibold uppercase tracking-wide text-slate-500"
            style={{ width: NAME_COLUMN_PX }}
          >
            CHW
          </div>
          <div className="relative" style={{ width: trackWidth }}>
            {hours.slice(0, -1).map((hour) => (
              <div
                key={hour.hour}
                className="absolute top-0 bottom-0 border-l border-slate-200 px-1.5 py-2 text-xs text-slate-500"
                style={{ left: (hour.hour - hours[0].hour) * 60 * PX_PER_MINUTE, width: 60 * PX_PER_MINUTE }}
              >
                {hour.label}
              </div>
            ))}
            <div className="py-2 text-xs text-transparent">.</div>
          </div>
        </div>

        {technicians.map((technician) => (
          <div key={technician.id} className="border-b border-slate-200 last:border-b-0">
            <div className="flex">
              <div
                className="shrink-0 border-r border-slate-200 px-3 py-2"
                style={{ width: NAME_COLUMN_PX }}
              >
                <div className="text-sm font-semibold text-slate-900">{technician.name}</div>
                {renderRowFooter?.(technician)}
              </div>

              <div
                className="relative"
                style={{ width: trackWidth, height: Math.max(technician.lane_count, 1) * ROW_LANE_PX }}
              >
                {/* Hour gridlines */}
                {hours.slice(0, -1).map((hour) => (
                  <div
                    key={hour.hour}
                    className="absolute top-0 bottom-0 border-l border-slate-100"
                    style={{ left: (hour.hour - hours[0].hour) * 60 * PX_PER_MINUTE }}
                  />
                ))}

                {nowOffsetMinutes != null && (
                  <div
                    className="absolute top-0 bottom-0 z-10 w-px bg-slate-900/50"
                    style={{ left: nowOffsetMinutes * PX_PER_MINUTE }}
                  />
                )}

                {technician.visits.map((visit) => (
                  <VisitBlock
                    key={visit.id}
                    visit={visit}
                    pxPerMinute={PX_PER_MINUTE}
                    lanePx={ROW_LANE_PX}
                    onSelect={onSelectVisit}
                  />
                ))}

                {technician.open_slots.map((slot) => (
                  <OpenSlotBlock
                    key={`slot-${slot.id}`}
                    slot={slot}
                    pxPerMinute={PX_PER_MINUTE}
                    lanePx={ROW_LANE_PX}
                    highlighted={slot.id === highlightedSlotId}
                    onOpen={() => onSelectSlot(slot, technician)}
                  />
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>

      {nowOffsetMinutes != null && (
        <div className="border-t border-slate-200 bg-slate-50 px-3 py-1.5 text-xs text-slate-500">
          The vertical line marks the current time ({nowLabel}).
        </div>
      )}
    </div>
  )
}
