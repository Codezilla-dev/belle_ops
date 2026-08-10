import { useEffect, useRef, useState } from 'react'
import { router } from '@inertiajs/react'

const POLL_MS = 5000

// Stands in for the real world changing under the coordinator: texts arriving,
// CHWs reporting from doorsteps, members calling in.
//
// Polling rather than websockets on purpose — a coordinator's board tolerates
// five seconds of staleness, and this is a fraction of the moving parts.
export default function LiveFeedBar() {
  const [live, setLive] = useState(true)
  const [simulating, setSimulating] = useState(false)
  const timer = useRef(null)

  useEffect(() => {
    if (!live) return undefined

    timer.current = setInterval(() => {
      // Partial reload: keep local state (open modals, filters, scroll) intact.
      router.reload({ only: ['technicians', 'waitlist', 'summary'], preserveState: true, preserveScroll: true })
    }, POLL_MS)

    return () => clearInterval(timer.current)
  }, [live])

  const simulate = () => {
    setSimulating(true)
    router.post('/simulation_events', {}, {
      preserveScroll: true,
      onFinish: () => setSimulating(false),
    })
  }

  return (
    <div className="mb-4 flex flex-wrap items-center gap-3 rounded-lg border border-slate-200 bg-white px-4 py-2.5">
      <span className="flex items-center gap-2 text-sm font-medium text-slate-700">
        <span className={`h-2 w-2 rounded-full ${live ? 'animate-pulse bg-emerald-500' : 'bg-slate-300'}`} />
        {live ? 'Live — refreshing every 5s' : 'Paused'}
      </span>

      <button
        type="button"
        onClick={() => setLive((value) => !value)}
        className="rounded-md border border-slate-300 px-2.5 py-1 text-xs font-medium text-slate-700 hover:bg-slate-50"
      >
        {live ? 'Pause' : 'Resume'}
      </button>

      <div className="ml-auto flex items-center gap-2">
        <span className="text-xs text-slate-500">Demo:</span>
        <button
          type="button"
          onClick={simulate}
          disabled={simulating}
          className="rounded-md bg-slate-900 px-3 py-1.5 text-xs font-medium text-white hover:bg-slate-700 disabled:opacity-50"
        >
          {simulating ? 'Sending…' : 'Simulate an incoming update'}
        </button>
      </div>
    </div>
  )
}
