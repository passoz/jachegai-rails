module Storage
  # Validated input command for a storage write.
  StoreCommand = Data.define(:owner_type, :owner_id, :filename, :content_type, :byte_size, :io) do
    def initialize(owner_type:, owner_id:, filename:, content_type:, byte_size:, io:)
      raise ArgumentError, "owner_type is required" if owner_type.blank?
      raise ArgumentError, "owner_id is required" if owner_id.blank?
      raise ArgumentError, "filename is required" if filename.blank?
      raise ArgumentError, "content_type is required" if content_type.blank?
      raise ArgumentError, "byte_size must be positive" unless byte_size.to_i.positive?
      raise ArgumentError, "io is required" if io.nil?

      super
    end
  end
end
