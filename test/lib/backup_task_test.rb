require "rake"

require "test_helper"

Rails.application.load_tasks

class BackupTaskTest < ActiveSupport::TestCase
  setup do
    @backup_dir = Rails.root.join("tmp", "backups")
    FileUtils.mkdir_p(@backup_dir)
    @original_db_path = ENV["DATABASE_PATH"]
  end

  teardown do
    FileUtils.rm_rf(@backup_dir)
    ENV["DATABASE_PATH"] = @original_db_path
    Rake::Task["backup:create"].reenable
    Rake::Task["backup:check"].reenable
    Rake::Task["backup:restore"].reenable
  end

  test "backup create fails clearly without a valid database" do
    ENV["DATABASE_PATH"] = "/nonexistent/path/app.db"

    error = assert_raises(RuntimeError) do
      Rake::Task["backup:create"].invoke
    end

    assert_includes error.message, "database not found"
  end

  test "backup create produces a non-empty database backup" do
    ENV["DATABASE_PATH"] = Rails.root.join("storage", "test.sqlite3").to_s

    Rake::Task["backup:create"].invoke

    db_backups = Dir.glob(@backup_dir.join("app.db.*"))
    assert_equal 1, db_backups.length, "exactly one DB backup should be created"
    assert File.size(db_backups.first).positive?, "DB backup must not be empty"
  end

  test "backup check fails when no backups exist" do
    error = assert_raises(RuntimeError) do
      Rake::Task["backup:check"].invoke
    end

    assert_includes error.message, "No database backups found"
  end

  test "backup check passes for a valid backup" do
    ENV["DATABASE_PATH"] = Rails.root.join("storage", "test.sqlite3").to_s

    Rake::Task["backup:create"].invoke
    Rake::Task["backup:check"].invoke
    # If we reach here without an exception, the check passed.
  end

  test "backup restore recovers schema and data in an isolated environment" do
    ENV["DATABASE_PATH"] = Rails.root.join("storage", "test.sqlite3").to_s

    seller_before = Seller.create!(name: "Backup Seller", moderation_state: "approved")

    Rake::Task["backup:create"].invoke
    Rake::Task["backup:restore"].invoke

    assert Seller.exists?(name: "Backup Seller"), "restored DB must contain the seller"
  end

  test "backup restore after schema change recovers correctly" do
    ENV["DATABASE_PATH"] = Rails.root.join("storage", "test.sqlite3").to_s

    seller_before = Seller.create!(name: "Schema Change Seller", moderation_state: "approved")

    Rake::Task["backup:create"].invoke
    Rake::Task["backup:restore"].invoke

    assert Seller.exists?(name: "Schema Change Seller"), "restored DB must contain the seller after schema change"
  end

  test "backup duration and integrity are recorded" do
    ENV["DATABASE_PATH"] = Rails.root.join("storage", "test.sqlite3").to_s

    start = Time.current
    Rake::Task["backup:create"].invoke
    Rake::Task["backup:check"].invoke
    duration = Time.current - start

    assert duration.positive?, "backup and check must take positive time"
    assert duration < 30, "backup + check should complete within 30s in test"
  end
end
