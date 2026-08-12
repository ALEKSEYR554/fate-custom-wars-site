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
      files = params[:sprite_files]

      if files.present?
        dir_path = Rails.root.join("storage", "servant_data", @servant.game_id)
        require "fileutils"
        FileUtils.mkdir_p(dir_path)

        # Массовая загрузка. Имя файла берется из оригинала.
        files.each do |uploaded_file|
          filename = uploaded_file.original_filename
          filename += ".png" unless filename.end_with?(".png")

          # 'wb' всегда жестко перезаписывает старый файл с таким же именем
          File.open(File.join(dir_path, filename), "wb") do |file|
            file.write(uploaded_file.read)
          end
        end
        flash[:notice] = "Спрайты успешно загружены!"
      else
        flash[:alert] = "Выберите файлы."
      end

      redirect_to edit_admin_servant_path(@servant.game_id)
    end

    def delete_sprite
      @servant = Servant.find_by!(game_id: params[:game_id])
      filename = params[:filename]
      file_path = Rails.root.join("storage", "servant_data", @servant.game_id, filename)

      File.delete(file_path) if File.exist?(file_path)

      redirect_to edit_admin_servant_path(@servant.game_id), notice: "Спрайт #{filename} удален."
    end

    def rename_sprite
      @servant = Servant.find_by!(game_id: params[:game_id])
      old_name = params[:old_filename]
      new_name = params[:new_filename].to_s.strip

      if old_name.present? && new_name.present?
        new_name += ".png" unless new_name.end_with?(".png")

        dir_path = Rails.root.join("storage", "servant_data", @servant.game_id)
        old_path = File.join(dir_path, old_name)
        new_path = File.join(dir_path, new_name)

        if File.exist?(old_path)
          File.rename(old_path, new_path)
          flash[:notice] = "Спрайт переименован в #{new_name}."
        else
          flash[:alert] = "Файл #{old_name} не найден."
        end
      else
        flash[:alert] = "Укажите новое имя файла."
      end

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
        :atlas_id, :en_name, :en_servant_class,
        :magic_defense, :magic_damage
      )
    end
  end
end
