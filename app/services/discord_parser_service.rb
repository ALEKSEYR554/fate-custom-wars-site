require "json"

class DiscordParserService
  def initialize(file_path)
    @file_path = file_path
    @manual_review_list = []
  end

  def call
    # Читаем JSON файл
    file = File.read(@file_path)
    data = JSON.parse(file)

    parsed_servants = []

    data["messages"].each do |msg|
      content = msg["content"]
      next if content.blank?

      # Проверяем, нужна ли ручная работа из ветки
      needs_manual = content.include?("в ветке")

      # Достаем картинку
      image_url = msg["attachments"]&.first&.dig("url")

      # Парсим текст
      parsed_data = parse_text(content)
      parsed_data[:image_url] = image_url
      parsed_data[:needs_manual_data] = needs_manual

      # Если нужна ручная проверка, сохраняем в отдельный список
      if needs_manual
        @manual_review_list << "#{parsed_data[:game_id]} - #{parsed_data[:name]}"
      end

      parsed_servants << parsed_data

      # Сразу сохраняем в базу данных!
      save_to_database(parsed_data)
    end

    # Выводим отчет в консоль
    puts "✅ Импорт завершен! Загружено слуг: #{parsed_servants.count}"
    puts "⚠️ Слуги, требующие ручного добавления данных из веток:"
    # puts @manual_review_list.join("\n")

    # Возвращаем результат если нужно
    parsed_servants
  end

  private

  def parse_text(text)
    data = {}
    text.gsub("**", "") # Убираем жирный шрифт, если есть
    # 1. Базовая информация
    data[:game_id] = text.match(/^(\dS-\d{3})/i)&.captures&.first
    data[:rarity] = data[:game_id]&.split("S")&.first&.to_i if data[:game_id]
    data[:region] = text.match(/^\dS-\d{3}\s*\((.*?)\)/i)&.captures&.first
    data[:alignment] = text.match(/Мировоззрение:\s*(.+)/)&.captures&.first
    data[:servant_class] = text.match(/Класс:\s*(.+)/)&.captures&.first
    data[:name] = text.match(/Имя:\s*(.+)/)&.captures&.first



    # 2. Характеристики: используем [^\s\(]+ чтобы ловить любые буквы (и русские, и английские)

    hp_match = text.match(/Выносливость:\s*([^\s\(]+)(?:\s*\((.*?)\))?/i)
    if hp_match
      data[:endurance_rank] = hp_match[1]
      data[:hp] = hp_match[2]&.scan(/\d+/)&.first&.to_i
    end

    str_match = text.match(/Сила:\s*([^\s\(]+)(?:\s*\((.*?)\))?/i)
    if str_match
      data[:strength_rank] = str_match[1]
      data[:damage] = str_match[2]&.scan(/\d+/)&.first&.to_i
    end

    agi_match = text.match(/Ловкость:\s*([^\s\(]+)(?:\s*\((.*?)\))?/i)
    if agi_match
      data[:agility_rank] = agi_match[1]
      data[:agility_modifier] = agi_match[2]&.scan(/\d+/)&.first&.to_i
    end

    magic_match = text.match(/(?:Магия|Мана):\s*([^\s\(]+)(?:\s*\((.*?)\))?/i)
    if magic_match
      data[:magic_rank] = magic_match[1]
      numbers = magic_match[2]&.scan(/\d+/)&.map(&:to_i) || []
      data[:magic_defense] = numbers[0]
      data[:magic_damage] = numbers[1]
    end

    luck_match = text.match(/Удача:\s*([^\s\(]+)(?:\s*\((.*?)\))?/i)
    if luck_match
      data[:luck_rank] = luck_match[1]
      data[:luck_modifier] = luck_match[2]&.scan(/\d+/)&.first&.to_i
    end

    np_match = text.match(/Н\.?Фантазм:\s*([^\s\(]+)/i)
    data[:np_rank] = np_match&.captures&.first

    # 3. Навыки (сделал поиск более надежным, если вдруг пропущен блок Классовых навыков)
    class_skills_match = text.match(/(Классовые Навыки|Классовый Навык):(.*?)(?=(Личные Навыки:|(Небесный Фантазм|Небесные Фантазмы)))/mi)
    data[:class_skills] = class_skills_match ? class_skills_match[2].strip : nil

    personal_skills_match = text.match(/Личные Навыки:(.*?)(?=(Небесный Фантазм|Небесные Фантазмы))/mi)
    data[:personal_skills] = personal_skills_match ? personal_skills_match[1].strip : nil

    noble_phantasm_match = text.match(/(Небесный Фантазм|Небесные Фантазмы)[:\s-]+(.*)/mi)
    data[:noble_phantasm] = noble_phantasm_match ? noble_phantasm_match[2].strip : nil

    # if text.include?("Нобукатсу")
    # p data
    # sleep(60)
    # end

    data
  end

  def save_to_database(data)
    # Ищем слугу по game_id (например 1S-001).
    # Если есть - обновляем, если нет - создаем нового.
    servant = Servant.find_or_initialize_by(game_id: data[:game_id])
    servant.update(data)
  end
end
