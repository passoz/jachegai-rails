# Applies deterministic bounded offset pagination to API collection queries.
class ApiPagination
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  attr_reader :records

  def initialize(scope:, page: nil, per_page: nil)
    @page = normalize_page(page)
    @per_page = normalize_per_page(per_page)
    @total = scope.except(:limit, :offset, :order).count
    @records = scope.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def meta
    {
      count: records.size,
      page: @page,
      per_page: @per_page,
      total: @total,
      total_pages: (@total.to_f / @per_page).ceil
    }
  end

  def self.values(page, per_page)
    pagination = allocate
    [ pagination.send(:normalize_page, page), pagination.send(:normalize_per_page, per_page) ]
  end

  private

  def normalize_page(value)
    parsed = value.to_i
    parsed.positive? ? parsed : 1
  end

  def normalize_per_page(value)
    return DEFAULT_PER_PAGE if value.blank? || value.to_i <= 0

    value.to_i.clamp(1, MAX_PER_PAGE)
  end
end
