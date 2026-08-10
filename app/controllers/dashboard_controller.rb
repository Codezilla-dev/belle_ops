# frozen_string_literal: true

class DashboardController < InertiaController
  def show
    render inertia: "Dashboard", props: CalendarDayPresenter.new.as_props
  end
end
