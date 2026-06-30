class Servant < ApplicationRecord
  # Срабатывает при создании новой записи в памяти
  after_initialize :set_default_layout, if: :new_record?

  def set_default_layout
    # Если шаблон не задан, используем стандартный
    self.page_layout ||= <<~LAYOUT
      [preview_image]
      [Базовые характеристики]
      [Классовые навыки]
      [Личные навыки]
      [Фантазмы]
      [Галерея sprite1: первый Ассеншн; sprite2: Второй Ассеншн; sprite3: Третий Ассеншн]

    LAYOUT
  end

  # Метод для старых слуг, у которых в базе пока пусто
  def layout_to_use
    page_layout.presence || <<~LAYOUT
      [preview_image]
      [Базовые характеристики]
      [Классовые навыки]
      [Личные навыки]
      [Фантазмы]
      [Галерея sprite1: первый Ассеншн; sprite2: Второй Ассеншн; sprite3: Третий Ассеншн]
      [Другой слуга: 4S-003]

    LAYOUT
  end
end
