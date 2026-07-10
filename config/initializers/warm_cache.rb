# config/initializers/warm_cache.rb

Rails.application.config.after_initialize do
  # Оборачиваем в rescue, чтобы сервер не падал при первом деплое,
  # когда базы данных или таблицы servants еще физически не существует.
  begin
    if ActiveRecord::Base.connection.table_exists?("servants")
      last_updated = Servant.maximum(:updated_at).to_i

      Rails.cache.fetch("unique_traits_#{last_updated}") do
        # Выполняем тяжелый запрос прямо во время загрузки Пумы
        Servant.pluck(Arel.sql("distinct unnest(traits)")).compact.reject(&:empty?).sort
      end

      Rails.logger.info "✅ Кэш трейтов успешно прогрет при старте сервера!"
    end
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
    Rails.logger.warn "⚠️ База данных недоступна, пропуск прогрева кэша."
  end
end
