module Storage
  # Immutable result of a successful storage operation.
  Intent = Data.define(:state, :provider, :storage_key, :byte_size, :checksum)
end
