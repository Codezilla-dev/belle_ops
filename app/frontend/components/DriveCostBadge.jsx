// Under each CHW's name: how much of their day is driving, and how much of that
// driving bought nothing.
export default function DriveCostBadge({ drive }) {
  return (
    <div className="mt-1 space-y-0.5 text-[11px] leading-tight">
      <div className="text-slate-500">
        <span className="font-medium text-slate-700">{drive.spent_minutes} min</span> driving
      </div>
      {drive.wasted_minutes > 0 && (
        <div className="text-rose-700" title="Drove out, visit didn't happen">
          {drive.wasted_minutes} min wasted
        </div>
      )}
      {drive.saved_minutes > 0 && (
        <div className="text-emerald-700" title="Cancelled early enough that the trip was called off">
          {drive.saved_minutes} min saved
        </div>
      )}
    </div>
  )
}
