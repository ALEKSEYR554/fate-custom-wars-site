module Api
  class ServantsController < ApiController
    def get_from_code
      servant = Servant.find_by(game_id: params[:servant_code])

      if servant
        content_url = "#{Rails.configuration.x.protocol}//servant-data.#{Rails.configuration.x.base_domain}/servant-page/#{servant.game_id}"

        # Отвечаем успешным JSON'ом
        render json: {
          success: true,
          data: {
            name: servant.name,
            class: servant.servant_class,
            description: servant.description
          },
          download_url: content_url
        }
      else
        # Если слуга не найден, возвращаем ошибку 404 (Not Found)
        render json: {
          success: false,
          error: "Слуга с именем #{params[:name]} не найден"
        }, status: :not_found
      end
    end
    def get_servant_with_traits
      # Начинаем с выборки всех слуг. Запрос в базу еще НЕ отправляется,
      # Рельсы ждут, пока мы не добавим все фильтры.
      @servants = Servant.all

      if params[:name].present?
        @servants = @servants.where("name ILIKE ?", "%#{params[:name]}%")
      end

      # 1. Фильтр по КЛАССУ (если передан)
      if params[:servant_class].present?
        # ILIKE делает поиск независимым от регистра (saber == Saber)
        class_to_search = params[:servant_class]
        case class_to_search
        when "Сейбер"
          class_to_search = "Сэйбер"
        end
        @servants = @servants.where("servant_class ILIKE ?", class_to_search)
      end

      # 2. Фильтр по РЕДКОСТИ (rarity=>3, rarity=5, rarity=<=2)
      if params[:rarity].present?
        rarity_param = params[:rarity]

        # Проверяем, начинается ли строка со знаков неравенства
        if rarity_param.match?(/^[><=]+/)
          # Вытаскиваем оператор (например ">") и само число (например "3")
          operator = rarity_param.match(/^[><=]+/)[0]
          value = rarity_param.match(/\d+/)[0].to_i

          # Защита от SQL-инъекций: разрешаем только безопасные математические знаки
          if %w[> < >= <= == =].include?(operator)
            operator = "=" if operator == "==" # SQL использует = для равенства
            @servants = @servants.where("rarity #{operator} ?", value)
          end
        else
          # Если передали просто число, например rarity=3
          @servants = @servants.where(rarity: rarity_param.to_i)
        end
      end

      # 3. Фильтр по ТРЕЙТАМ (traits=[male,saberface] или traits=male,saberface)
      if params[:traits].present?
        # Убираем скобки и разбиваем по запятой
        traits_array = params[:traits].tr("[]", "").split(",").map(&:strip)

        # Проходимся по каждому трейту, который запросил пользователь
        traits_array.each do |trait|
          # EXISTS и unnest распаковывают массив traits в виртуальную таблицу
          # %...% позволяет искать часть слова. Например, %enuma% найдет weakToEnumaElish
          # ILIKE игнорирует большие/маленькие буквы
          @servants = @servants.where(
            "EXISTS (SELECT 1 FROM unnest(servants.traits) AS t WHERE t ILIKE ?)",
            "%#{trait}%"
          )
        end
      end

      if @servants.empty?
        render json: {
          success: false,
          error: "Слуги с заданными параметрами не найдены"
        }, status: :not_found
      else
        formated_servants = @servants.map do |servant|
          attrs = servant.attributes.except("id", "created_at", "updated_at")
          ordered_data = {
            "game_id"       => attrs.delete("game_id"),
            "name"          => attrs.delete("name"),
            "servant_class" => attrs.delete("servant_class"),
            "rarity"        => attrs.delete("rarity"),
            "region"        => attrs.delete("region"),
            "alignment"     => attrs.delete("alignment")
          }
          ordered_data.merge(attrs)
        end
        # Формируем и отправляем JSON-ответ, как в Telegram API
        render json: {
          success: true, # В телеграме успешные запросы начинаются с ok: true
          result_count: @servants.count,
          # Отдаем данные, но скрываем системные колонки id, created_at и т.д.
          result: formated_servants
        }, status: :ok
      end
    end
  end
end
