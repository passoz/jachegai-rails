module Identity
  # Immutable result of a successful identity verification.
  Intent = Data.define(:state, :provider, :subject_id, :email)
end
