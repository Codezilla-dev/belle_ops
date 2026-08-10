// A hole in a CHW's day, drawn in the window the cancelled visit used to
// occupy. If somebody on the waitlist fits, they're named right here so filling
// it is one click rather than a hunt through a list.
export default function OpenSlotBlock({ slot, pxPerMinute, lanePx, highlighted, onOpen }) {
  const suggestion = slot.candidates[0]

  return (
    <button
      type="button"
      onClick={() => onOpen(slot)}
      style={{
        left: slot.offset_minutes * pxPerMinute,
        width: Math.max(slot.duration_minutes * pxPerMinute - 3, 34),
        top: slot.lane * lanePx + 4,
        height: lanePx - 8,
      }}
      className={`absolute z-10 overflow-hidden rounded-md border-2 border-dashed border-indigo-500 bg-indigo-50 px-1.5 py-1 text-left text-[11px] leading-tight text-indigo-900 hover:z-20 hover:bg-indigo-100 focus:z-20 focus:outline-none focus:ring-2 focus:ring-indigo-500 ${
        highlighted ? 'z-20 ring-4 ring-indigo-400/60' : ''
      }`}
    >
      <span className="block truncate font-semibold">
        {suggestion ? `+ ${suggestion.member_name}` : 'Open slot'}
      </span>
      <span className="block truncate opacity-80">
        {suggestion ? `${slot.time_label} · fill` : `${slot.time_label} · no match`}
      </span>
    </button>
  )
}
