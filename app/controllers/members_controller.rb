# frozen_string_literal: true

class MembersController < InertiaController
  def index
    render inertia: "Members", props: MembersPresenter.new.as_props
  end
end
