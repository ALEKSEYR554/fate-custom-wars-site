require_relative "../config/environment"
require "discordrb"

# Токен берем из переменных среды сервера
TOKEN = ENV["DISCORD_BOT_TOKEN"]
# Сюда впиши ID твоего канала (копируется через правый клик по каналу в Discord)
CHANNEL_ID = 1097158993207631902

bot = Discordrb::Bot.new(token: TOKEN, intents: [ :server_messages, :message_content ])

def sync_servant(message)
  text = message.content
  return if text.blank?

  if message.thread?
    history = message.thread.history(100).sort_by(&:timestamp)
    history.each do |msg|
      text += "\n" + msg.content
    end
  end

  parser = DiscordParserService.new(nil)
  parsed_data = parser.send(:parse_text, text)

  if parsed_data && parsed_data[:game_id]
    servant = Servant.find_or_initialize_by(game_id: parsed_data[:game_id])

    # assign_attributes записывает данные в память, но НЕ сохраняет в базу
    servant.assign_attributes(parsed_data)

    # Магия Рельсов: проверяем, отличаются ли новые данные от того, что уже в базе
    if servant.changed?
      changed_fields = servant.changes.keys

      # Выводим в консоль ТОЛЬКО те поля, которые реально изменились
      puts "🔄 [#{servant.game_id}] Обнаружены изменения в полях: #{changed_fields.join(', ')}"

      # Распечатываем новые значения для дебага:
      changed_fields.each do |field|
        puts "   -> #{field}: #{servant.send(field).inspect}"
      end

      # Когда закончишь дебаг, раскомментируй эту строчку, чтобы сохранять в базу:
      # servant.save!
    else
      puts "⏩ [#{servant.game_id}] Изменений нет. Пропуск."
    end
  end
end

# 1. Ловим новые сообщения в канале
bot.message(in: CHANNEL_ID) do |event|
  sync_servant(event.message)
end

# 2. Ловим редактирование старых сообщений
bot.message_edit(in: CHANNEL_ID) do |event|
  sync_servant(event.message)
end

# 4. Ловим редактирование сообщений ВНУТРИ веток
bot.message_edit do |event|
  if event.channel.type == 11 && event.channel.parent_id == CHANNEL_ID
    # ID ветки всегда совпадает с ID родительского сообщения
    parent_message = event.channel.parent.load_message(event.channel.id)
    sync_servant(parent_message) if parent_message
  end
end

puts "Бот запущен и слушает Discord!"
bot.run
