# frozen_string_literal: true

# Drives the fake live feed. In a real deployment these would be webhooks from
# the SMS gateway, the IVR and the CHW app.
class SimulationEventsController < InertiaController
  def create
    event = SimulationService.next_event!

    if event
      redirect_back_or_to root_path, notice: event.message
    else
      redirect_back_or_to root_path, alert: "Nothing left to simulate — reset with bin/rails db:seed."
    end
  end
end
