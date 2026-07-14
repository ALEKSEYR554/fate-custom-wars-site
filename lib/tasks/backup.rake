namespace :backup do
  # Общий метод для отправки
  def send_to_telegram(filepath, caption)
    require "net/http"
    require "uri"

    token = ENV["TELEGRAM_BOT_TOKEN"]
    chat_id = ENV["TELEGRAM_CHAT_ID"]

    if token.blank? || chat_id.blank?
      puts "❌ Токен или Chat ID не настроены!"
      return
    end

    uri = URI.parse("https://api.telegram.org/bot#{token}/sendDocument")
    request = Net::HTTP::Post.new(uri)

    form_data = [
      [ "chat_id", chat_id ],
      [ "document", File.open(filepath) ]
    ]
    form_data << [ "caption", caption ] if caption

    request.set_form(form_data, "multipart/form-data")

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    puts "Ответ Telegram для #{filepath}: #{response.body}"
  end

  desc "Бэкап только Слуг"
  task servants: :environment do
    Rake::Task["servants:export_all"].invoke
    caption = "💾 Авто-бэкап СЛУГ: #{Time.now.strftime("%Y-%m-%d %H:%M")}"
    send_to_telegram("all_servants.yml", caption)
    puts "✅ Бэкап Слуг завершен!"
  end

  desc "Бэкап только Карт"
  task ces: :environment do
    Rake::Task["ces:export_all"].invoke
    caption = "🎴 Авто-бэкап КАРТ (CE): #{Time.now.strftime("%Y-%m-%d %H:%M")}"
    send_to_telegram("all_ces.yml", caption)
    puts "✅ Бэкап Карт завершен!"
  end
end
