module Admin
  class BaseController < ApplicationController
    # Встроенная базовая защита браузера. Поменяй пароль!
    http_basic_authenticate_with name: "#{ENV["CUSTOM_WARS_ADMIN_LOGIN"]}", password: "#{ENV["CUSTOM_WARS_ADMIN_PASSWORD"]}"


    protected
    # Отложенный бэкап (Таймер 3 минуты)
    def schedule_backup(type = "servants")
      job_ticket = SecureRandom.hex
      cache_key = "backup_ticket_#{type}"
      Rails.cache.write(cache_key, job_ticket)

      Thread.new do
        sleep 3.minutes
        if Rails.cache.read(cache_key) == job_ticket
          Rails.cache.delete(cache_key)
          system("RAILS_ENV=production /root/.local/share/mise/shims/bundle exec rails backup:#{type} >> log/backup.log 2>&1")
        end
      end
    end

    def force_backup(type = "servants")
      Rails.cache.delete("backup_ticket_#{type}")
      Thread.new do
        system("RAILS_ENV=production /root/.local/share/mise/shims/bundle exec rails backup:#{type} >> log/backup.log 2>&1")
      end
    end
  end
end
