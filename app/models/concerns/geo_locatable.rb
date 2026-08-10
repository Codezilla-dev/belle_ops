# frozen_string_literal: true

# Straight-line distance between two records that carry lat/lng.
#
# We have coordinates but no routing service, so "how far out of the way is this
# member?" is answered with a haversine distance and a flat speed assumption.
# Good enough to rank waitlist candidates against each other, which is all we
# ask of it.
module GeoLocatable
  extend ActiveSupport::Concern

  EARTH_RADIUS_KM = 6371.0

  # Effective city driving speed, km/h. Deliberately pessimistic — these are
  # residential streets with a parking hunt at the end.
  ASSUMED_SPEED_KMH = 20.0
  MINIMUM_DRIVE_MINUTES = 5

  def distance_km_to(other)
    return nil unless located? && other.respond_to?(:located?) && other.located?

    d_lat = deg_to_rad(other.lat - lat)
    d_lng = deg_to_rad(other.lng - lng)

    a = (Math.sin(d_lat / 2)**2) +
        (Math.cos(deg_to_rad(lat)) * Math.cos(deg_to_rad(other.lat)) * (Math.sin(d_lng / 2)**2))

    EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  end

  # Rough drive time for a leg we have no real estimate for (a waitlist member
  # slotted into someone else's cancelled visit).
  def estimated_drive_minutes_to(other)
    km = distance_km_to(other)
    return MINIMUM_DRIVE_MINUTES if km.nil?

    [ (km / ASSUMED_SPEED_KMH * 60).round, MINIMUM_DRIVE_MINUTES ].max
  end

  def located?
    lat.present? && lng.present?
  end

  private

  def deg_to_rad(degrees)
    degrees * Math::PI / 180
  end
end
