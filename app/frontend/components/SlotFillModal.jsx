import { useEffect, useState } from 'react'
import { router } from '@inertiajs/react'

export default function SlotFillModal({ slot, technicianName, onClose }) {
  const [submittingId, setSubmittingId] = useState(null)

  useEffect(() => {
    const onKey = (event) => event.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  if (!slot) return null

  const fill = (candidate) => {
    setSubmittingId(candidate.request_id)
    router.post(
      '/slot_fills',
      { slot_id: slot.id, reschedule_request_id: candidate.request_id },
      { onFinish: () => { setSubmittingId(null); onClose() } },
    )
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4" onClick={onClose}>
      <div
        className="max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white shadow-xl"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-4 border-b border-slate-200 px-5 py-4">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Fill the {slot.time_label} slot</h2>
            <p className="text-sm text-slate-500">
              {technicianName} is free here — {slot.vacated_by}&apos;s visit fell through.
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
          {slot.candidates.length === 0 ? (
            <p className="text-sm text-slate-600">
              Nobody on the waitlist wants a {slot.timeframe} visit. Leave it open, or move someone
              from another day.
            </p>
          ) : (
            <ul className="space-y-3">
              {slot.candidates.map((candidate) => (
                <li
                  key={candidate.request_id}
                  className={`rounded-lg border p-3 ${
                    candidate.reachable
                      ? 'border-slate-200 hover:border-slate-300'
                      : 'border-slate-200 bg-slate-50 opacity-75'
                  }`}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-slate-900">{candidate.member_name}</span>
                        <span className="text-sm text-slate-500">{candidate.member_age}</span>
                        {candidate.clinical_priority === 'high' && (
                          <span className="rounded-full bg-rose-100 px-2 py-0.5 text-[11px] font-medium text-rose-800">
                            Clinically urgent
                          </span>
                        )}
                      </div>
                      <p className="mt-1 text-xs text-slate-600">{candidate.reasons.join(' · ')}</p>
                      <p
                        className={`mt-1 text-xs ${
                          candidate.reachable ? 'text-slate-500' : 'font-medium text-amber-700'
                        }`}
                      >
                        {candidate.reachable
                          ? `Roughly ${candidate.drive_minutes} min drive — fits the ${slot.slack_minutes} min gap`
                          : `Roughly ${candidate.drive_minutes} min drive — the CHW would run late`}
                      </p>
                    </div>
                    <button
                      type="button"
                      disabled={submittingId !== null}
                      onClick={() => fill(candidate)}
                      className="shrink-0 rounded-md bg-slate-900 px-3 py-1.5 text-sm font-medium text-white hover:bg-slate-700 disabled:opacity-50"
                    >
                      {submittingId === candidate.request_id ? 'Adding…' : 'Add to schedule'}
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  )
}
