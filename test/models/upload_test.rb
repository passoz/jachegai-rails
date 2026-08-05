require "test_helper"

class UploadTest < ActiveSupport::TestCase
  test "upload stores validated media metadata" do
    seller = Seller.create!(name: "Loja de Mídia")
    upload = Upload.create!(
      owner: seller,
      storage_key: "sellers/#{seller.id}/logo.jpg",
      filename: "logo.jpg",
      content_type: "image/jpeg",
      byte_size: 2048
    )
    assert upload.id.present?
    assert_equal seller.id, upload.owner_id
    assert_equal "Seller", upload.owner_type
  end

  test "upload requires storage metadata" do
    upload = Upload.new(owner: Seller.new, storage_key: "", filename: "", content_type: "", byte_size: nil)
    assert_not upload.valid?
    assert upload.errors[:storage_key].any?
    assert upload.errors[:filename].any?
    assert upload.errors[:content_type].any?
  end
end
