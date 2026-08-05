require "test_helper"
require "rake"
Rails.application.load_tasks

class BootstrapAdminTaskTest < ActiveSupport::TestCase
  test "bootstrap_admin creates admin user with admin role" do
    ENV["EMAIL"] = "admin@example.com"
    ENV["PASSWORD"] = "password123"
    ENV["FULL_NAME"] = "Root Admin"

    Rake::Task["jachegai:bootstrap_admin"].reenable
    Rake::Task["jachegai:bootstrap_admin"].invoke

    user = User.find_by(email: "admin@example.com")
    assert user.present?
    assert user.admin?
    assert_equal "Root Admin", user.full_name
  ensure
    ENV.delete("EMAIL")
    ENV.delete("PASSWORD")
    ENV.delete("FULL_NAME")
  end

  test "bootstrap_admin fails when required environment is missing" do
    ENV.delete("EMAIL")
    ENV.delete("ADMIN_EMAIL")
    ENV.delete("PASSWORD")
    ENV.delete("ADMIN_PASSWORD")
    Rake::Task["jachegai:bootstrap_admin"].reenable
    error = assert_raises(SystemExit) { Rake::Task["jachegai:bootstrap_admin"].invoke }
    assert_equal 1, error.status
  end

  test "bootstrap_admin does not overwrite an existing user" do
    email = "preserve@example.com"
    user = User.create!(email: email, password: "originalpass", full_name: "Original", active: false)
    ENV["EMAIL"] = email
    ENV["PASSWORD"] = "differentpass"
    ENV["FULL_NAME"] = "Changed"
    Rake::Task["jachegai:bootstrap_admin"].reenable
    Rake::Task["jachegai:bootstrap_admin"].invoke
    user.reload
    assert_equal "Original", user.full_name
    refute user.active?
    assert user.authenticate("originalpass")
    refute user.authenticate("differentpass")
  ensure
    ENV.delete("EMAIL")
    ENV.delete("PASSWORD")
    ENV.delete("FULL_NAME")
  end

  test "bootstrap_admin upgrades existing user to admin" do
    user = User.create!(email: "existing@example.com", password: "password123", full_name: "Existing")
    RoleAssignment.create!(user: user, role: "customer")

    ENV["EMAIL"] = "existing@example.com"
    ENV["PASSWORD"] = "password123"

    Rake::Task["jachegai:bootstrap_admin"].reenable
    Rake::Task["jachegai:bootstrap_admin"].invoke

    user.reload
    assert user.admin?
    assert_includes user.roles, :customer
  ensure
    ENV.delete("EMAIL")
    ENV.delete("PASSWORD")
  end
end
