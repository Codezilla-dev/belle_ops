import { useEffect, useMemo, useState } from 'react'
import { router } from '@inertiajs/react'

function CandidateRow({ candidate, slot, submittingId, onFill }) {
  return (
    <li
      className={`rounded-lg border p-3 ${
        candidate.recommended ? 'border-slate-200 hover:border-slate-300' : 'border-slate-200 bg-slate-50'
      }`}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <span className="font-semibold text-slate-900">{candidate.member_name}</span>
            <span className="text-sm text-slate-500">{candidate.member_age}</span>
            {candidate.clinical_priority === 'high' && (
              <span className="rounded-full bg-rose-100 px-2 py-0.5 text-[11px] font-medium text-rose-800">
                Clinically urgent
              </span>
            )}
            {candidate.recommended ? (
              <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-[11px] font-medium text-emerald-800">
                Good fit
              </span>
            ) : (
              <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-medium text-amber-800">
                Needs an override
              </span>
            )}
          </div>

          {candidate.reasons.length > 0 && (
            <p className="mt-1 text-xs text-slate-600">{candidate.reasons.join(' · ')}</p>
          )}

          {candidate.warnings.length > 0 && (
            <ul className="mt-1 space-y-0.5">
              {candidate.warnings.map((warning) => (
                <li key={warning} className="text-xs text-amber-700">
                  ⚠ {warning}
                </li>
              ))}
            </ul>
          )}

          {candidate.recommended && (
            <p className="mt-1 text-xs text-slate-500">
              Roughly {candidate.drive_minutes} min drive — fits the {slot.slack_minutes} min gap
            </p>
          )}
        </div>

        <button
          type="button"
          disabled={submittingId !== null}
          onClick={() => onFill(candidate)}
          className={`shrink-0 rounded-md px-3 py-1.5 text-sm font-medium disabled:opacity-50 ${
            candidate.recommended
              ? 'bg-slate-900 text-white hover:bg-slate-700'
              : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-100'
          }`}
        >
          {submittingId === candidate.request_id ? 'Adding…' : 'Add to schedule'}
        </button>
      </div>
    </li>
  )
}

export default function SlotFillModal({ slot, technicianName, onClose }) {
  const [submittingId, setSubmittingId] = useState(null)
  const [query, setQuery] = useState('')

  useEffect(() => {
    const onKey = (event) => event.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  // Reset the search when a different slot is opened.
  useEffect(() => setQuery(''), [slot?.id])

  const { recommended, others } = useMemo(() => {
    const matching = (slot?.candidates ?? []).filter((candidate) =>
      candidate.member_name.toLowerCase().includes(query.toLowerCase()),
    )
    return {
      recommended: matching.filter((candidate) => candidate.recommended),
      others: matching.filter((candidate) => !candidate.recommended),
    }
  }, [slot, query])

  if (!slot) return null

  const fill = (candidate) => {
    setSubmittingId(candidate.request_id)
    router.post(
      '/slot_fills',
      { slot_id: slot.id, reschedule_request_id: candidate.request_id },
      { onFinish: () => { setSubmittingId(null); onClose() } },
    )
  }

  const rowProps = { slot, submittingId, onFill: fill }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4" onClick={onClose}>
      <div
        className="flex max-h-[85vh] w-full max-w-lg flex-col overflow-hidden rounded-xl bg-white shadow-xl"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-4 border-b border-slate-200 px-5 py-4">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Fill the {slot.time_label} slot</h2>
            <p className="text-sm text-slate-500">
              {technicianName} is free here — {slot.vacated_by}&apos;s visit fell through. Anyone on
              the waitlist can go in.
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

        {slot.candidates.length > 4 && (
          <div className="border-b border-slate-200 px-5 py-3">
            <input
              type="search"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search the waitlist by name"
              className="w-full rounded-md border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500"
            />
          </div>
        )}

        <div className="overflow-y-auto px-5 py-4">
          {slot.candidates.length === 0 ? (
            <p className="text-sm text-slate-600">
              Nobody is on the waitlist. Leave the slot open, or move someone from another day.
            </p>
          ) : recommended.length === 0 && others.length === 0 ? (
            <p className="text-sm text-slate-600">Nobody on the waitlist matches that search.</p>
          ) : (
            <>
              {recommended.length > 0 && (
                <>
                  <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Fits this slot
                  </h3>
                  <ul className="space-y-3">
                    {recommended.map((candidate) => (
                      <CandidateRow key={candidate.request_id} candidate={candidate} {...rowProps} />
                    ))}
                  </ul>
                </>
              )}

              {others.length > 0 && (
                <>
                  <h3
                    className={`mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500 ${
                      recommended.length > 0 ? 'mt-5' : ''
                    }`}
                  >
                    {recommended.length > 0
                      ? 'Everyone else on the waitlist'
                      : 'Nobody fits cleanly — these would need an override'}
                  </h3>
                  <ul className="space-y-3">
                    {others.map((candidate) => (
                      <CandidateRow key={candidate.request_id} candidate={candidate} {...rowProps} />
                    ))}
                  </ul>
                </>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}
