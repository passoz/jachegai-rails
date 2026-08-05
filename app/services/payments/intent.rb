module Payments
  Intent = Data.define(:state, :provider, :method, :external_reference, :amount)
end
