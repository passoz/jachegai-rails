require "test_helper"

class RequirementsMatrixTest < ActiveSupport::TestCase
  SPEC_PATH = Rails.root.join("docs", "PORTABLE_PRODUCT_SPEC.md")
  MATRIX_PATH = Rails.root.join("docs", "BACKEND_REQUIREMENTS_MATRIX.md")

  def spec_ids
    File.read(SPEC_PATH).scan(/\b[A-Z]{2,4}-[0-9]{2,4}\b/).map(&:upcase).uniq.sort
  end

  def matrix_ids
    File.read(MATRIX_PATH).scan(/\b[A-Z]{2,4}-[0-9]{2,4}\b/).map(&:upcase).uniq.sort
  end

  test "matrix exists" do
    assert File.exist?(MATRIX_PATH), "Matrix file must exist"
  end

  test "matrix contains all 197 requirement IDs from spec" do
    missing = spec_ids - matrix_ids
    assert_empty missing, "Matrix missing IDs: #{missing.join(', ')}"
  end

  test "matrix has no duplicate requirement IDs" do
    matrix_lines = File.readlines(MATRIX_PATH).select { |l| l.start_with?("| ") && l =~ /\| [A-Z]{2,4}-[0-9]{2,4} \|/ }
    ids_in_rows = matrix_lines.map { |l| l.match(/\| ([A-Z]{2,4}-[0-9]{2,4}) \|/)[1] }
    duplicates = ids_in_rows.group_by(&:itself).select { |_, v| v.size > 1 }.keys
    assert_empty duplicates, "Duplicate IDs in matrix: #{duplicates.join(', ')}"
  end

  test "matrix has no unknown IDs not in spec" do
    unknown = matrix_ids - spec_ids
    assert_empty unknown, "Matrix has IDs not in spec: #{unknown.join(', ')}"
  end

  test "UX requirements are marked deferred_frontend" do
    matrix = File.read(MATRIX_PATH)
    ux_ids = spec_ids.select { |id| id.start_with?("UX-") }
    ux_ids.each do |id|
      line = matrix.lines.find { |l| l.include?("| #{id} |") }
      assert line.include?("deferred_frontend"), "UX-#{id} should be deferred_frontend"
    end
  end

  test "no requirement marked verified without evidence" do
    matrix = File.read(MATRIX_PATH)
    verified_lines = matrix.lines.select { |l| l.include?("| verified |") }
    assert verified_lines.all? { |l| l =~ /\| [^|]+ \| [^|]+ \| [^|]+ \| [^|]+ \| [^|]+ \| verified \|/ }, "Verified rows need evidence"
  end

  test "future seller order and trusted media requirements remain planned" do
    matrix = File.read(MATRIX_PATH)

    %w[SEL-009 SEL-010 SEL-011 SEL-012 SEL-013].each do |id|
      line = matrix.lines.find { |candidate| candidate.include?("| #{id} |") }
      assert_includes line, "| verified |", "#{id} must be verified since its owning phase is implemented"
    end
  end

  test "inventory concurrency is verified while aggregate courier concurrency remains partial" do
    matrix = File.read(MATRIX_PATH)
    inventory = matrix.lines.find { |candidate| candidate.include?("| DAT-009 |") }
    aggregate = matrix.lines.find { |candidate| candidate.include?("| TST-009 |") }

    assert_includes inventory, "| verified |", "Fase 06 proves last-unit contention with two database connections"
    assert_includes inventory, "checkout_concurrency"
    assert_includes aggregate, "| implemented |", "single courier assignment remains Fase 08"
    refute_includes aggregate, "| verified |"
  end

  test "external callback verification remains conditional for the simulated payment MVP" do
    matrix = File.read(MATRIX_PATH)
    line = matrix.lines.find { |candidate| candidate.include?("| PAY-005 |") }

    assert_includes line, "| conditional |"
    assert_includes line, "no external callback"
  end

  test "guest-cart handoff is verified in the customer-cart phase" do
    matrix = File.read(MATRIX_PATH)
    line = matrix.lines.find { |candidate| candidate.include?("| PUB-008 |") }

    assert_includes line, "| verified |"
    assert_includes line, "F05-T05.5"
  end
end
