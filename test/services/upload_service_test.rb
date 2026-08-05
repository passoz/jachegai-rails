require "test_helper"

class UploadServiceTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Upload Service Seller", moderation_state: "approved")
    @file = StringIO.new("fake image content")
    @file.define_singleton_method(:original_filename) { "logo.jpg" }
    @file.define_singleton_method(:content_type) { "image/jpeg" }
  end

  test "stores a validated media upload with server-generated key" do
    upload = UploadService.new(owner: @seller, file: @file).store!

    assert upload.persisted?
    assert_equal "Seller", upload.owner_type
    assert_equal @seller.id, upload.owner_id
    assert_equal "logo.jpg", upload.filename
    assert_equal "image/jpeg", upload.content_type
    assert upload.byte_size.positive?
    assert upload.storage_key.start_with?("uploads/"), "storage_key must be server-generated under uploads/"
    refute_includes upload.storage_key, ".."
  end

  test "rejects files above the size limit" do
    big_file = StringIO.new("x" * (UploadService::MAX_BYTE_SIZE + 1))
    big_file.define_singleton_method(:original_filename) { "big.jpg" }
    big_file.define_singleton_method(:content_type) { "image/jpeg" }

    error = assert_raises(DomainError) do
      UploadService.new(owner: @seller, file: big_file).store!
    end
    assert_equal "file_too_large", error.code
  end

  test "rejects content types outside the allow-list" do
    dangerous = StringIO.new("script")
    dangerous.define_singleton_method(:original_filename) { "evil.rb" }
    dangerous.define_singleton_method(:content_type) { "application/x-ruby" }

    error = assert_raises(DomainError) do
      UploadService.new(owner: @seller, file: dangerous).store!
    end
    assert_equal "unsupported_content_type", error.code
  end

  test "rejects client-provided paths with traversal" do
    traversal = StringIO.new("x")
    traversal.define_singleton_method(:original_filename) { "../../etc/passwd" }
    traversal.define_singleton_method(:content_type) { "image/png" }

    error = assert_raises(DomainError) do
      UploadService.new(owner: @seller, file: traversal).store!
    end
    assert_equal "unsafe_filename", error.code
  end

  test "serves executables with attachment disposition, not inline" do
    dangerous = StringIO.new("MZ\x90\x00")
    dangerous.define_singleton_method(:original_filename) { "app.exe" }
    dangerous.define_singleton_method(:content_type) { "application/x-msdownload" }

    # executable types are rejected outright at store time
    assert_raises(DomainError) do
      UploadService.new(owner: @seller, file: dangerous).store!
    end
  end
end
