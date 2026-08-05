require "test_helper"

class ApiPaginationTest < ActiveSupport::TestCase
  setup do
    30.times { |index| Seller.create!(name: "Pagination Seller #{index}") }
  end

  test "uses bounded defaults and reports complete metadata" do
    pagination = ApiPagination.new(scope: Seller.order(:id))

    assert_equal 25, pagination.records.size
    assert_equal({ count: 25, page: 1, per_page: 25, total: 30, total_pages: 2 }, pagination.meta)
  end

  test "normalizes invalid values and clamps page size" do
    assert_equal [ 1, 25 ], ApiPagination.values(nil, nil)
    assert_equal [ 1, 25 ], ApiPagination.values(-1, 0)
    assert_equal [ 2, 100 ], ApiPagination.values(2, 500)
  end
end
