# frozen_string_literal: true

class DashboardController < InertiaController
  def show
    render inertia: "Dashboard", props: { day: Belle::CURRENT_DAY.to_s }
  end
end
