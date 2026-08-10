# frozen_string_literal: true

# Filling an open slot with somebody off the waitlist.
class SlotFillsController < InertiaController
  def create
    request_record = RescheduleRequest.find(params[:reschedule_request_id])
    slot = find_slot(params[:slot_id])

    if slot.nil?
      return redirect_to root_path, inertia: { errors: { slot: "That slot is no longer open." } }
    end

    visit = SchedulingService.fill!(request: request_record, slot: slot)

    redirect_to root_path, notice: "#{visit.member.name} added to #{visit.technician.name}'s " \
                                   "#{visit.scheduled_start.in_time_zone.strftime('%-l:%M %p')} slot."
  rescue SchedulingService::SlotUnavailable, SchedulingService::RequestUnavailable => e
    redirect_to root_path, inertia: { errors: { slot: e.message } }
  end

  private

  def find_slot(slot_id)
    OpenSlotsService.for_day.fillable_slots.find { |slot| slot.id == slot_id.to_i }
  end
end
