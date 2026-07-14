module Admin
  class ServantsController < BaseController
    def index
      @servants = Servant.order(:sort_id, :id)
    end

    def edit
      @servant = Servant.find_by!(game_id: params[:game_id])

      # Ищем все .png файлы в папке этого слуги
      dir_path = Rails.root.join("storage", "servant_data", @servant.game_id)
      if File.directory?(dir_path)
        @sprites = Dir.glob("#{dir_path}/*.png").map { |f| File.basename(f) }.sort
      else
        @sprites = []
      end
    end

    def update
      @servant = Servant.find_by!(game_id: params[:game_id])

      # Обработка трейтов (превращаем строку из запятых обратно в массив PostgreSQL)
      traits_str = params[:servant].delete(:traits_string)
      if traits_str
        @servant.traits = traits_str.split(",").map(&:strip).reject(&:empty?)
      end

      ce_str = params[:servant].delete(:craft_essences_string)
      if ce_str
        @servant.craft_essences = ce_str.split(",").map(&:strip).reject(&:empty?)
      end

      if @servant.update(servant_params)
        schedule_backup("servants")
        # Возвращаем в список после успеха
        redirect_to admin_servants_path, notice: "Слуга #{@servant.name} успешно обновлен!"
      else
        render :edit
      end
    end

    def new
      @servant = Servant.new

      max_sort = Servant.maximum(:sort_id) || -100

      # Задаем значение по умолчанию для формы
      @servant.sort_id = max_sort + 100
    end

    def sync_atlas
      @servant = Servant.find_by!(game_id: params[:game_id])

      if @servant.atlas_id.blank?
        redirect_to edit_admin_servant_path(@servant.game_id), alert: "Сначала укажите Atlas ID и сохраните слугу!"
        return
      end

      require "net/http"
      require "uri"
      require "json"

      begin
        uri = URI("https://api.atlasacademy.io/nice/JP/servant/#{@servant.atlas_id}?lang=en")
        response = Net::HTTP.get(uri)
        data = JSON.parse(response)

        # Собираем трейты (Основной + Возвышения + Костюмы)
        traits_temp = data["traits"] || []

        if data.dig("ascensionAdd", "individuality", "ascension")
          data["ascensionAdd"]["individuality"]["ascension"].values.each { |t| traits_temp += t }
        end

        if data.dig("ascensionAdd", "individuality", "costume")
          data["ascensionAdd"]["individuality"]["costume"].values.each { |t| traits_temp += t }
        end

        # Фильтруем unknown и берем только уникальные имена
        traits_out = traits_temp.reject { |t| t["name"] == "unknown" }.map { |t| t["name"] }.uniq

        # Обновляем слугу
        @servant.update!(
          en_name: data["name"],
          en_servant_class: data["className"],
          traits: traits_out
        )

        schedule_backup("servants") # Сохраняем бэкап

        redirect_to edit_admin_servant_path(@servant.game_id), notice: "Успешно синхронизировано с Atlas Academy!"
      rescue => e
        redirect_to edit_admin_servant_path(@servant.game_id), alert: "Ошибка API: #{e.message}"
      end
    end

    def create
      @servant = Servant.new(servant_params)

      traits_str = params[:servant].delete(:traits_string)
      @servant.traits = traits_str.split(",").map(&:strip).reject(&:empty?) if traits_str

      ce_str = params[:servant].delete(:craft_essences_string)
      @servant.craft_essences = ce_str.split(",").map(&:strip).reject(&:empty?) if ce_str

      if @servant.save
        schedule_backup("servants")
        redirect_to admin_servants_path, notice: "Слуга #{@servant.name} успешно создан!"
      else
        render :new
      end
    end

    def upload_sprite
      @servant = Servant.find_by!(game_id: params[:game_id])
      uploaded_file = params[:sprite_file]
      sprite_name = params[:sprite_name].strip

      if uploaded_file && sprite_name.present?
        # Защита: принудительно добавляем .png, если пользователь забыл
        sprite_name += ".png" unless sprite_name.end_with?(".png")

        # Создаем папку, если её еще нет
        dir_path = Rails.root.join("storage", "servant_data", @servant.game_id)
        require "fileutils"
        FileUtils.mkdir_p(dir_path)

        # Сохраняем файл
        File.open(File.join(dir_path, sprite_name), "wb") do |file|
          file.write(uploaded_file.read)
        end

        flash[:notice] = "Спрайт #{sprite_name} успешно загружен!"
      else
        flash[:alert] = "Укажите имя файла и выберите PNG изображение."
      end

      # Возвращаем обратно на страницу редактирования
      redirect_to edit_admin_servant_path(@servant.game_id)
    end

    def backup_telegram
      force_backup("servants")

      redirect_to admin_servants_path, notice: "Таймеры сброшены. Бэкап формируется и сейчас придет в Telegram."
    end

    private

    def servant_params
      # Перечисляем все поля, которые разрешено менять через форму
      params.require(:servant).permit(
        :name, :servant_class, :rarity, :region, :alignment, :attack_range, :sort_id, :game_id,
        :hp, :damage, :endurance_rank, :strength_rank, :agility_rank, :agility_modifier,
        :magic_rank, :luck_rank, :np_rank,
        :class_skills, :personal_skills, :noble_phantasm, :page_layout,
        :atlas_id, :en_name, :en_servant_class
      )
    end
  end
end
