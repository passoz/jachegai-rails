class UploadService
  MAX_BYTE_SIZE = 10.megabytes

  ALLOWED_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/webp
    image/gif
    application/pdf
    text/plain
  ].freeze

  EXECUTABLE_CONTENT_TYPES = %w[
    application/x-msdownload
    application/x-msdos-program
    application/x-msi
    application/x-sh
    application/x-executable
    application/x-ruby
    application/x-php
    application/x-python-code
    application/javascript
    text/javascript
    application/xhtml+xml
    application/xml
    text/html
    image/svg+xml
  ].freeze

  def initialize(owner:, file:)
    @owner = owner
    @file = file
  end

  def store!
    validate!
    filename = File.basename(@file.original_filename.to_s)
    content_type = @file.content_type.to_s
    byte_size = @file.size

    storage_key = generate_storage_key(content_type)

    blob = ActiveStorage::Blob.create_and_upload!(
      io: @file,
      filename: filename,
      content_type: content_type,
      service_name: ActiveStorage::Blob.service.name
    )

    @owner.uploads.create!(
      storage_key: storage_key,
      filename: filename,
      content_type: content_type,
      byte_size: byte_size
    )
  rescue ActiveStorage::IntegrityError => error
    raise DomainError.new(code: :storage_integrity_error, message: error.message, http_status: :unprocessable_entity)
  end

  def self.safe_to_serve_inline?(content_type)
    !EXECUTABLE_CONTENT_TYPES.include?(content_type.to_s)
  end

  private

  def validate!
    raise DomainError.new(code: :file_too_large, message: "file exceeds maximum size", http_status: :unprocessable_entity) if @file.size > MAX_BYTE_SIZE
    raise DomainError.new(code: :unsupported_content_type, message: "content type not allowed", http_status: :unprocessable_entity) unless ALLOWED_CONTENT_TYPES.include?(@file.content_type.to_s)
    raise DomainError.new(code: :unsafe_filename, message: "filename is not safe", http_status: :unprocessable_entity) unless safe_filename?(@file.original_filename.to_s)
  end

  def safe_filename?(filename)
    base = File.basename(filename.to_s)
    base.present? && base == filename && !base.include?("..") && !base.include?("/") && !base.include?("\\")
  end

  def generate_storage_key(content_type)
    ext = Rack::Mime::MIME_TYPES.invert[content_type] || File.extname(@file.original_filename.to_s).downcase
    "uploads/#{SecureRandom.hex(16)}#{ext}"
  end
end
