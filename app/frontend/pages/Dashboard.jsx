import { useState } from 'react'
import Layout from '../components/Layout'
import CalendarGrid from '../components/CalendarGrid'
import VisitModal from '../components/VisitModal'
import DaySummary, { Legend } from '../components/DaySummary'

// Props arrive from Rails in snake_case (see CalendarDayPresenter); component
// props below are camelCase as usual.
export default function Dashboard({
  day_label: dayLabel,
  hours,
  minutes_in_day: minutesInDay,
  technicians,
  now_offset_minutes: nowOffsetMinutes,
  now_label: nowLabel,
  summary,
}) {
  const [selectedId, setSelectedId] = useState(null)

  // Look the visit up out of props on every render, so a poll that changes its
  // status refreshes the open modal instead of showing a stale copy.
  const selectedVisit =
    technicians.flatMap((technician) => technician.visits).find((visit) => visit.id === selectedId) ?? null

  return (
    <Layout>
      <div className="mb-4">
        <h1 className="text-xl font-semibold tracking-tight">Today&apos;s schedule</h1>
        <p className="text-sm text-slate-500">{dayLabel}</p>
      </div>

      <DaySummary summary={summary} />

      <CalendarGrid
        hours={hours}
        minutesInDay={minutesInDay}
        technicians={technicians}
        nowOffsetMinutes={nowOffsetMinutes}
        nowLabel={nowLabel}
        onSelectVisit={(visit) => setSelectedId(visit.id)}
      />

      <Legend />

      <VisitModal visit={selectedVisit} onClose={() => setSelectedId(null)} />
    </Layout>
  )
}
