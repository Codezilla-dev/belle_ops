// One place to decide what a visit looks like, shared by the calendar blocks,
// the legend and the modal.
//
// Colour carries the confirmation status — that is the thing the coordinator is
// hunting for. Whether the visit has already happened is carried by muting and
// strike-through, so the two signals never compete.

export const CONFIRMATION_STYLES = {
  confirmed: {
    label: 'Confirmed',
    block: 'bg-emerald-100 border-emerald-400 text-emerald-950',
    dot: 'bg-emerald-500',
  },
  no_reply: {
    label: 'No reply',
    block: 'bg-amber-100 border-amber-400 text-amber-950',
    dot: 'bg-amber-500',
  },
  wants_reschedule: {
    label: 'Wants reschedule',
    block: 'bg-sky-100 border-sky-400 text-sky-950',
    dot: 'bg-sky-500',
  },
  declined: {
    label: 'Declined',
    block: 'bg-rose-100 border-rose-400 text-rose-950',
    dot: 'bg-rose-500',
  },
}

export const STATUS_LABELS = {
  scheduled: 'Scheduled',
  completed: 'Completed',
  cancelled: 'Cancelled',
  no_show: 'No show',
}

export const CANCELLATION_REASON_LABELS = {
  no_answer: 'No answer at the door',
  member_unavailable: 'Member unavailable',
  member_declined: 'Member declined',
  no_caregiver: 'No caregiver to let the CHW in',
  hospitalized: 'Member hospitalized',
}

export const CHANNEL_LABELS = {
  text: 'by text',
  voice: 'by automated call',
  on_site: 'at the door',
}

export function confirmationStyle(status) {
  return CONFIRMATION_STYLES[status] ?? CONFIRMATION_STYLES.no_reply
}
