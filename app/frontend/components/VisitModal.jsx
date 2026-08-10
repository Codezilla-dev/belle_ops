import { useEffect } from 'react'
import {
  CANCELLATION_REASON_LABELS,
  CHANNEL_LABELS,
  STATUS_LABELS,
  confirmationStyle,
} from './visitStyles'

function Row({ label, children }) {
  return (
    <div className="flex gap-3 py-1.5 text-sm">
      <dt className="w-36 shrink-0 text-slate-500">{label}</dt>
      <dd className="text-slate-900">{children}</dd>
    </div>
  )
}

export default function VisitModal({ visit, onClose }) {
  useEffect(() => {
    const onKey = (event) => event.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  if (!visit) return null

  const style = confirmationStyle(visit.confirmation_status)
  const cancellation = visit.cancellation

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4" onClick={onClose}>
      <div
        className="max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white shadow-xl"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-4 border-b border-slate-200 px-5 py-4">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">
              {visit.no_show_risk && <span className="mr-1">⚠️</span>}
              {visit.member_name}
            </h2>
            <p className="text-sm text-slate-500">
              {visit.time_label} · {visit.visit_type === 'foot_care' ? 'Foot care' : 'Follow-up'}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-md px-2 py-1 text-slate-400 hover:bg-slate-100 hover:text-slate-700"
            aria-label="Close"
          >
            ✕
          </button>
        </div>

        <div className="px-5 py-4">
          <div className="mb-4 flex flex-wrap items-center gap-2">
            <span className={`rounded-full border px-2.5 py-0.5 text-xs font-medium ${style.block}`}>
              {style.label}
            </span>
            <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-700">
              {STATUS_LABELS[visit.status]}
            </span>
            {visit.backfill && (
              <span className="rounded-full bg-indigo-100 px-2.5 py-0.5 text-xs font-medium text-indigo-800">
                Added from waitlist
              </span>
            )}
          </div>

          <dl className="divide-y divide-slate-100">
            <Row label="Age">{visit.member_age}</Row>
            <Row label="Address">{visit.address}</Row>
            <Row label="Prior no-shows">
              {visit.prior_no_shows}
              {visit.no_show_risk && (
                <span className="ml-2 text-amber-700">— call ahead before driving out</span>
              )}
            </Row>
            {visit.household_shared && (
              <Row label="Household">Another member lives at this address</Row>
            )}
            <Row label="Drive to get here">
              {visit.drive_minutes} min
              {visit.drive_avoided && <span className="ml-2 text-emerald-700">— saved</span>}
            </Row>
            <Row label="Reminder">
              {visit.reminder_sent_at
                ? `Sent ${visit.reminder_sent_at} · ${visit.reminder_response ?? 'no response'}`
                : 'Not sent'}
            </Row>
          </dl>

          {cancellation && (
            <div className="mt-4 rounded-lg border border-slate-200 bg-slate-50 p-3 text-sm">
              <p className="font-semibold text-slate-900">
                {STATUS_LABELS[visit.status]} — {CANCELLATION_REASON_LABELS[cancellation.reason] ?? cancellation.reason}
              </p>
              <p className="mt-1 text-slate-600">
                Found out {CHANNEL_LABELS[cancellation.channel] ?? cancellation.channel} at{' '}
                {cancellation.cancelled_at} (via {cancellation.cancelled_by.replace('_', ' ')}).
              </p>
              <p className={`mt-1 font-medium ${cancellation.drive_avoided ? 'text-emerald-700' : 'text-rose-700'}`}>
                {cancellation.drive_avoided
                  ? `${cancellation.drive_minutes} min drive saved — we heard before the CHW set off.`
                  : `${cancellation.drive_minutes} min drive already spent.`}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
