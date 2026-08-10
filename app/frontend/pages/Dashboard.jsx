import { useState } from 'react'
import Layout from '../components/Layout'
import CalendarGrid from '../components/CalendarGrid'
import VisitModal from '../components/VisitModal'
import SlotFillModal from '../components/SlotFillModal'
import WaitlistPanel from '../components/WaitlistPanel'
import DaySummary, { Legend } from '../components/DaySummary'
import DriveCostBadge from '../components/DriveCostBadge'

// Props arrive from Rails in snake_case (see CalendarDayPresenter); component
// props below are camelCase as usual.
export default function Dashboard({
  day_label: dayLabel,
  hours,
  minutes_in_day: minutesInDay,
  technicians,
  now_offset_minutes: nowOffsetMinutes,
  now_label: nowLabel,
  waitlist,
  summary,
}) {
  const [selectedVisitId, setSelectedVisitId] = useState(null)
  const [selectedSlot, setSelectedSlot] = useState(null)
  const [highlightedSlotId, setHighlightedSlotId] = useState(null)

  // Look these up out of props on every render, so a refresh that changes the
  // underlying record updates what's open instead of showing a stale copy.
  const allVisits = technicians.flatMap((technician) => technician.visits)
  const selectedVisit = allVisits.find((visit) => visit.id === selectedVisitId) ?? null

  const openSlotModal = (slot, technician) =>
    setSelectedSlot({ ...slot, technicianName: technician.name })

  const jumpToSlot = (slotId) => {
    setHighlightedSlotId(slotId)
    const technician = technicians.find((t) => t.open_slots.some((slot) => slot.id === slotId))
    const slot = technician?.open_slots.find((s) => s.id === slotId)
    if (slot) openSlotModal(slot, technician)
  }

  return (
    <Layout>
      <div className="mb-4">
        <h1 className="text-xl font-semibold tracking-tight">Today&apos;s schedule</h1>
        <p className="text-sm text-slate-500">{dayLabel}</p>
      </div>

      <DaySummary summary={summary} />

      <div className="grid gap-4 xl:grid-cols-[minmax(0,1fr)_320px]">
        <div>
          <CalendarGrid
            hours={hours}
            minutesInDay={minutesInDay}
            technicians={technicians}
            nowOffsetMinutes={nowOffsetMinutes}
            nowLabel={nowLabel}
            onSelectVisit={(visit) => setSelectedVisitId(visit.id)}
            onSelectSlot={openSlotModal}
            highlightedSlotId={highlightedSlotId}
            renderRowFooter={(technician) => <DriveCostBadge drive={technician.drive} />}
          />
          <Legend />
        </div>

        <WaitlistPanel waitlist={waitlist} onJumpToSlot={jumpToSlot} />
      </div>

      <VisitModal visit={selectedVisit} onClose={() => setSelectedVisitId(null)} />
      <SlotFillModal
        slot={selectedSlot}
        technicianName={selectedSlot?.technicianName}
        onClose={() => setSelectedSlot(null)}
      />
    </Layout>
  )
}
