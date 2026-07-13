namespace :cards do
  desc "Импорт карточек CE из JSON"
  task import: :environment do
    require "json"

    # Файл cards.json должен лежать в корне проекта
    data = JSON.parse(File.read("cards.json"))

    data["messages"].each do |msg|
      text = msg["content"]
      next if text.blank?

      game_id = text.match(/(CE-\d{3})/i)&.captures&.first
      name = text.match(/Название:\s*(.+)/i)&.captures&.first
      effect = text.match(/Эффект:\s*(.+)/mi)&.captures&.first

      if game_id
        ce = CraftEssence.find_or_initialize_by(game_id: game_id)
        ce.update(name: name, effect: effect)
      end
    end
    puts "✅ Карты загружены: #{CraftEssence.count}"
  end
end
