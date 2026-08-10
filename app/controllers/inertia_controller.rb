# frozen_string_literal: true

class InertiaController < ApplicationController
  # One-off confirmations ("Ada W. added to Priya N.'s 3:00 PM slot") ride along
  # with every response so any page can surface them.
  inertia_share flash: -> { { notice: flash.notice, alert: flash.alert } }
end
