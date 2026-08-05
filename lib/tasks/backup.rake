namespace :backup do
  desc "Create a backup of the SQLite database and uploads directory"
  task create: :environment do
    backup_dir = Rails.root.join("tmp", "backups")
    FileUtils.mkdir_p(backup_dir)

    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    db_src = Pathname.new(ENV.fetch("DATABASE_PATH", Rails.root.join("data", "app.db")))
    db_dst = backup_dir.join("app.db.#{timestamp}")
    uploads_dst = backup_dir.join("uploads.#{timestamp}.tar.gz")

    unless db_src.exist?
      raise "Backup failed: database not found at #{db_src}"
    end

    FileUtils.cp(db_src, db_dst)

    storage_root = Pathname.new(ENV.fetch("STORAGE_ROOT", Rails.root.join("storage", "uploads")))
    if storage_root.exist?
      sh "tar -czf #{uploads_dst} -C #{storage_root} ."
    end

    puts "Backup created: #{db_dst}"
    puts "Uploads backup: #{uploads_dst}" if storage_root.exist?
  end

  desc "Verify the integrity of the latest backup"
  task check: :environment do
    backup_dir = Rails.root.join("tmp", "backups")
    db_backups = Dir.glob(backup_dir.join("app.db.*")).sort.reverse
    uploads_backups = Dir.glob(backup_dir.join("uploads.*.tar.gz")).sort.reverse

    if db_backups.empty?
      raise "No database backups found in #{backup_dir}"
    end

    latest_db = db_backups.first
    size = File.size(latest_db)

    if size.zero?
      raise "Backup integrity check failed: #{latest_db} is empty (0 bytes)"
    end

    # Verify SQLite integrity using the sqlite3 gem (available via ActiveRecord)
    db = SQLite3::Database.new(latest_db.to_s)
    result = db.execute("PRAGMA integrity_check;").flatten.first
    db.close

    unless result == "ok"
      raise "Backup integrity check failed: #{result}"
    end

    puts "Backup integrity OK: #{latest_db} (#{size} bytes)"

    if uploads_backups.any?
      latest_uploads = uploads_backups.first
      uploads_size = File.size(latest_uploads)
      if uploads_size.zero?
        raise "Uploads backup integrity check failed: #{latest_uploads} is empty"
      end
      puts "Uploads backup integrity OK: #{latest_uploads} (#{uploads_size} bytes)"
    end
  end

  desc "Restore database and uploads from the latest backup"
  task restore: :environment do
    backup_dir = Rails.root.join("tmp", "backups")
    db_backups = Dir.glob(backup_dir.join("app.db.*")).sort.reverse

    if db_backups.empty?
      raise "No database backups found in #{backup_dir}"
    end

    latest_db = db_backups.first
    target_db = Pathname.new(ENV.fetch("DATABASE_PATH", Rails.root.join("data", "app.db")))

    FileUtils.cp(latest_db, target_db)
    puts "Database restored from: #{latest_db}"

    uploads_backup = Dir.glob(backup_dir.join("uploads.*.tar.gz")).sort.reverse.first
    if uploads_backup
      storage_root = Pathname.new(ENV.fetch("STORAGE_ROOT", Rails.root.join("storage", "uploads")))
      FileUtils.rm_rf(storage_root)
      FileUtils.mkdir_p(storage_root)
      sh "tar -xzf #{uploads_backup} -C #{storage_root}"
      puts "Uploads restored from: #{uploads_backup}"
    end
  end
end
