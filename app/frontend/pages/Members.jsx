import { useState } from 'react'
import Layout from '../components/Layout'

const STATUS_TONES = {
  'No-show today': 'text-rose-700',
  'Cancelled today': 'text-rose-700',
  'Unconfirmed, still ahead': 'text-amber-700',
  'On the waitlist': 'text-indigo-700',
  'Seen today': 'text-emerald-700',
}

function TechnicianWatch({ technicians, flaggedIds }) {
  if (technicians.length === 0) return null

  return (
    <section className="mb-6 rounded-lg border border-slate-200 bg-white">
      <div className="border-b border-slate-200 px-4 py-3">
        <h2 className="text-sm font-semibold text-slate-900">CHW watch</h2>
        <p className="text-xs text-slate-500">
          Most visits fall through because of the member, not the CHW. This is here to catch the
          exception — a run of failures concentrated on one person is worth a conversation, not an
          accusation.
        </p>
        <p className="mt-1.5 text-xs font-medium text-slate-700">
          {flaggedIds.length === 0
            ? 'Nobody stands out today — the failures are spread across the team.'
            : `${flaggedIds.length} CHW${flaggedIds.length === 1 ? '' : 's'} worth asking about.`}
        </p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-4 py-2 font-medium">CHW</th>
              <th className="px-4 py-2 font-medium">Visits</th>
              <th className="px-4 py-2 font-medium">Fell through</th>
              <th className="px-4 py-2 font-medium">Found at the door</th>
              <th className="px-4 py-2 font-medium">Drive wasted</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {technicians.map((technician) => {
              const flagged = flaggedIds.includes(technician.id)
              return (
                <tr key={technician.id} className={flagged ? 'bg-amber-50' : ''}>
                  <td className="px-4 py-2 font-medium text-slate-900">
                    {flagged && <span title="Worth asking about">⚑ </span>}
                    {technician.name}
                  </td>
                  <td className="px-4 py-2 text-slate-600">{technician.visits}</td>
                  <td className={`px-4 py-2 ${flagged ? 'font-semibold text-amber-800' : 'text-slate-600'}`}>
                    {technician.fell_through} ({technician.fell_through_pct}%)
                  </td>
                  <td className="px-4 py-2 text-slate-600">{technician.on_site_discoveries}</td>
                  <td className="px-4 py-2 text-slate-600">{technician.wasted_drive_minutes} min</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </section>
  )
}

export default function Members({ members, technicians, flagged_technician_ids: flaggedIds }) {
  const [query, setQuery] = useState('')
  const [riskOnly, setRiskOnly] = useState(false)

  const visible = members.filter((member) => {
    if (riskOnly && !member.risk) return false
    return member.name.toLowerCase().includes(query.toLowerCase())
  })

  return (
    <Layout>
      <div className="mb-4">
        <h1 className="text-xl font-semibold tracking-tight">Members</h1>
        <p className="text-sm text-slate-500">
          Sorted by no-show history — the people most likely to cost a wasted trip are at the top.
        </p>
      </div>

      <TechnicianWatch technicians={technicians} flaggedIds={flaggedIds} />

      <div className="mb-3 flex flex-wrap items-center gap-3">
        <input
          type="search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Search by name"
          className="w-64 rounded-md border-slate-300 text-sm shadow-sm focus:border-slate-500 focus:ring-slate-500"
        />
        <label className="flex items-center gap-2 text-sm text-slate-700">
          <input
            type="checkbox"
            checked={riskOnly}
            onChange={(event) => setRiskOnly(event.target.checked)}
            className="rounded border-slate-300 text-slate-900 focus:ring-slate-500"
          />
          Only members with a no-show history
        </label>
        <span className="text-sm text-slate-500">
          {visible.length} of {members.length}
        </span>
      </div>

      <div className="overflow-x-auto rounded-lg border border-slate-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-4 py-2 font-medium">Member</th>
              <th className="px-4 py-2 font-medium">Age</th>
              <th className="px-4 py-2 font-medium">Prior no-shows</th>
              <th className="px-4 py-2 font-medium">Today</th>
              <th className="px-4 py-2 font-medium">Cancelled</th>
              <th className="px-4 py-2 font-medium">No-showed</th>
              <th className="px-4 py-2 font-medium">Address</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {visible.map((member) => (
              <tr key={member.id} className={member.risk ? 'bg-amber-50/60' : ''}>
                <td className="px-4 py-2 font-medium text-slate-900">
                  {member.risk && <span title="2+ prior no-shows">⚠️ </span>}
                  {member.name}
                </td>
                <td className="px-4 py-2 text-slate-600">{member.age}</td>
                <td className={`px-4 py-2 ${member.risk ? 'font-semibold text-amber-800' : 'text-slate-600'}`}>
                  {member.prior_no_shows}
                </td>
                <td className={`px-4 py-2 ${STATUS_TONES[member.today_status] ?? 'text-slate-600'}`}>
                  {member.today_status}
                </td>
                <td className="px-4 py-2 text-slate-600">{member.cancelled || '—'}</td>
                <td className="px-4 py-2 text-slate-600">{member.no_shows || '—'}</td>
                <td className="px-4 py-2 text-slate-500">{member.address}</td>
              </tr>
            ))}
          </tbody>
        </table>

        {visible.length === 0 && (
          <p className="px-4 py-6 text-sm text-slate-500">No members match that search.</p>
        )}
      </div>
    </Layout>
  )
}
