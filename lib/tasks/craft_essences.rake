namespace :ces do
  desc "Экспорт ВСЕХ карт (CE) в YML"
  task export_all: :environment do
    require "yaml"

    data = {}
    CraftEssence.order(:game_id).each do |ce|
      attrs = ce.attributes.except("id", "created_at", "updated_at")

      if attrs["effect"].present?
        attrs["effect"] = attrs["effect"].gsub("\r\n", "\n").gsub(/[ \t]+$/, "").strip
      end

      data[ce.game_id] = attrs
    end

    File.write("all_ces.yml", data.to_yaml(line_width: -1))
    puts "✅ Выгружено карт: #{CraftEssence.count}"
  end

  desc "Импорт ВСЕХ карт (CE) из YML"
  task import_all: :environment do
    require "yaml"

    file_path = "all_ces.yml"
    unless File.exist?(file_path)
      puts "❌ Файл #{file_path} не найден!"
      exit
    end

    data = YAML.load_file(file_path)
    updated_count = 0

    data.each do |game_id, attributes|
      ce = CraftEssence.find_or_initialize_by(game_id: game_id)
      ce.update(attributes)
      updated_count += 1
    end

    puts "✅ Успешно синхронизировано карт: #{updated_count}!"
  end
end
