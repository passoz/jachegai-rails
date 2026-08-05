module Notifications
  # Immutable result of a successful notification dispatch.
  Intent = Data.define(:state, :provider, :external_reference, :channel)
end
