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
    # === 3. УМНЫЙ ПАРСЕР НАВЫКОВ (State Machine) ===
    data[:class_skills] = ""
    data[:personal_skills] = ""
    data[:noble_phantasm] = ""

    current_section = :none

    text.each_line do |line|
      clean_line = line.strip

      # Игнорируем мусорные строки
      next if clean_line.match?(/^\(?Смотр.*?ветк.*?\)?$/i)
      next if clean_line.match?(/^Спрайт/i)

      # Переключаем "тумблер" записи, если видим заголовок
      if clean_line.match?(/^[\(\*\_]*Классовые Навыки/i)
        current_section = :class_skills
        next
      elsif clean_line.match?(/^[\(\*\_]*Личные Навыки/i)
        current_section = :personal_skills
        next
      elsif clean_line.match?(/^[\(\*\_]*Небесны[ей]\sФантазм[ы]?/i)
        current_section = :noble_phantasm

        # Обрезаем заголовок (вместе со скобками и цифрами), если текст написан на этой же строке
        remainder = clean_line.sub(/^[\(\*\_]*Небесны[ей]\sФантазм[ы]?(?:\s*\d+)?[\)\*\_]*[:\s-]+/i, "")
        data[:noble_phantasm] << remainder + "\n" if remainder.present?
        next
      end

      # Пишем строку в ту секцию, которая сейчас активна
      case current_section
      when :class_skills
        data[:class_skills] << line
      when :personal_skills
        data[:personal_skills] << line
      when :noble_phantasm
        data[:noble_phantasm] << line
      end
    end

    # Очищаем пустоты по краям
    data[:class_skills] = data[:class_skills].strip.presence
    data[:personal_skills] = data[:personal_skills].strip.presence
    data[:noble_phantasm] = data[:noble_phantasm].strip.presence

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
