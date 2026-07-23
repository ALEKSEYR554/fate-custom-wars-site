require "discordrb"

# Запускать бота только если есть токен и это не консоль (чтобы не мешать rails c)
if ENV["DISCORD_BOT_TOKEN"].present? && !defined?(Rails::Console)
  Thread.new do
    CHANNEL_ID = 1097158993207631902
    DEBUG_CHANNEL_ID = 1529870425440391198
    bot = Discordrb::Bot.new(token: ENV["DISCORD_BOT_TOKEN"], intents: [ :all ])

    def sync_servant(message, bot)
      text = message.content
      return if text.blank?

      if message.thread?
        history = message.thread.history(100).sort_by(&:timestamp)
        history.each { |msg| text += "\n" + msg.content }
      end

      parser = DiscordParserService.new(nil)
      parsed_data = parser.send(:parse_text, text)

      if parsed_data && parsed_data[:game_id]
        servant = Servant.find_or_initialize_by(game_id: parsed_data[:game_id])
        is_new = servant.new_record?

        # Даем новому слуге номер в конец списка
        if is_new
          max_sort = Servant.maximum(:sort_id) || -100
          servant.sort_id = max_sort + 100
        end

        servant.assign_attributes(parsed_data)

        if servant.changed?
          changed_fields = servant.changes.keys
          Rails.logger.info "🔄 [#{servant.game_id}] Обнаружены изменения в полях: #{changed_fields.join(', ')}"
          changed_fields.each do |field|
            Rails.logger.info "   -> #{field}: #{servant.send(field).inspect}"
          end
          servant.save! # Раскомментируй для сохранения в базу

          msg_text = if is_new
            "✨ ** Слуга #{servant.game_id} (#{servant.name})** создан в базе!"
          else
            "🔄 **[#{servant.game_id}] #{servant.name}** обновлен!\nИзменились: `#{changed_fields.join(', ')}`"
          end

          bot.send_message(DEBUG_CHANNEL_ID, msg_text)
        end
      end
    end

    bot.message(in: CHANNEL_ID) { |event| sync_servant(event.message, bot) }
    bot.message_edit(in: CHANNEL_ID) { |event| sync_servant(event.message, bot) }

    bot.message do |event|
      if event.channel.type == 11 && event.channel.parent_id == CHANNEL_ID
        parent_message = event.channel.parent.load_message(event.channel.id)
        sync_servant(parent_message, bot) if parent_message
      end
    end

    bot.message_edit do |event|
      if event.channel.type == 11 && event.channel.parent_id == CHANNEL_ID
        parent_message = event.channel.parent.load_message(event.channel.id)
        sync_servant(parent_message, bot) if parent_message
      end
    end

    Rails.logger.info "🤖 Discord Бот запущен внутри Puma!"
    bot.run
  end
end
