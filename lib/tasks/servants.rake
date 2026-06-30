namespace :servants do
  desc "Экспорт слуг в виде пары Имя - класс (для проверки соответствия с Atlas API)"
  task export_atlas: :environment do
    output = []
    Servant.order(:game_id).each do |s|
      output << "#{s.name} - #{s.servant_class}"
    end
    File.write("servants_from_db.txt", output.join("\n"))
  end

  desc "Экспорт ВСЕЙ базы данных в YML для ручных правок"
  task export_all: :environment do
    require "yaml"

    data = {}
    Servant.order(:game_id).each do |s|
      attrs = s.attributes.except("id", "created_at", "updated_at")

      %w[class_skills personal_skills noble_phantasm].each do |field|
        if attrs[field].present?
          clean_text = attrs[field].gsub("\r\n", "\n").gsub(/[ \t]+$/, "").strip

          attrs[field] = clean_text
        end
      end

      data[s.game_id] = attrs
    end

    # line_width: -1 запрещает YAML принудительно переносить длинные предложения
    File.write("all_servants.yml", data.to_yaml(line_width: -1))

    puts "✅ Полная база выгружена! Экспортировано слуг: #{Servant.count}"
    puts "📂 Файл сохранен как: all_servants.yml"
  end

  desc "Импорт ВСЕЙ базы данных из YML обратно"
  task import_all: :environment do
    require "yaml"

    file_path = "all_servants.yml"
    unless File.exist?(file_path)
      puts "❌ Файл #{file_path} не найден!"
      exit
    end

    data = YAML.load_file(file_path)
    updated_count = 0

    data.each do |game_id, attributes|
      servant = Servant.find_or_initialize_by(game_id: game_id)
      servant.update(attributes)
      updated_count += 1
    end

    puts "✅ Успешно синхронизировано слуг: #{updated_count}!"
  end

  desc "Экспорт слуг (которым нужна ручная правка) в файл для редактирования"
  task export_manual: :environment do
    require "yaml"

    # Ищем всех, у кого стоит галочка "нужна ручная работа"
    servants = Servant.where(needs_manual_data: true)

    if servants.empty?
      puts "🎉 Нет слуг, требующих ручной правки!"
      exit
    end

    data = {}
    servants.each do |s|
      # Сохраняем только тексты навыков, чтобы не засорять файл лишним
      data[s.game_id] = {
        "name" => s.name,
        "class_skills" => s.class_skills,
        "personal_skills" => s.personal_skills,
        "noble_phantasm" => s.noble_phantasm
      }
    end

    # Сохраняем в корень проекта
    File.write("manual_servants.yml", data.to_yaml)
    puts "✅ Экспортировано слуг: #{servants.count}"
    puts "📂 Файл сохранен как: manual_servants.yml в корне проекта."
  end

  desc "Импорт исправленных слуг обратно в базу данных"
  task import_manual: :environment do
    require "yaml"

    file_path = "manual_servants.yml"
    unless File.exist?(file_path)
      puts "❌ Файл #{file_path} не найден!"
      exit
    end

    # Читаем наш YAML
    data = YAML.load_file(file_path)
    updated_count = 0

    data.each do |game_id, fields|
      servant = Servant.find_by(game_id: game_id)

      if servant
        servant.update(
          class_skills: fields["class_skills"],
          personal_skills: fields["personal_skills"],
          noble_phantasm: fields["noble_phantasm"],
          needs_manual_data: false # Снимаем галочку! Он больше не проблемный
        )
        updated_count += 1
        puts "Обновлен: #{game_id} - #{servant.name}"
      end
    end

    puts "✅ Успешно обновлено слуг: #{updated_count}!"
    puts "🗑️ Можешь удалить файл manual_servants.yml"
  end
end
