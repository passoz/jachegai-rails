module AppendOnlyRecord
  extend ActiveSupport::Concern

  included do
    before_update :reject_append_only_mutation
    before_destroy :reject_append_only_mutation
  end

  private

  def reject_append_only_mutation
    errors.add(:base, "record is append-only")
    throw(:abort)
  end
end
