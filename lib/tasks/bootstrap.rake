namespace :jachegai do
  desc "Create or update the initial admin user (EMAIL, PASSWORD, FULL_NAME env vars)"
  task bootstrap_admin: :environment do
    email = ENV["EMAIL"] || ENV["ADMIN_EMAIL"]
    password = ENV["PASSWORD"] || ENV["ADMIN_PASSWORD"]
    full_name = ENV["FULL_NAME"] || ENV["ADMIN_FULL_NAME"] || "Administrator"

    if email.blank? || password.blank?
      abort "Usage: EMAIL=admin@example.com PASSWORD=... bin/rails jachegai:bootstrap_admin"
    end

    user = User.find_or_initialize_by(email: email.strip.downcase)
    if user.new_record?
      user.full_name = full_name
      user.password = password
      user.save!
    end

    RoleAssignment.find_or_create_by!(user: user, role: "admin")

    puts "Admin ready: #{user.email} (id=#{user.id})"
  end
end
