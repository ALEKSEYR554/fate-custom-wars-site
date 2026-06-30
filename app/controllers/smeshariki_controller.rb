class SmesharikiController < ApplicationController
  def serve
    safe_filename = File.basename(params[:filename])
    file_path = Rails.root.join("storage", "smeshariki_files", safe_filename)

    if File.exist?(file_path)
      send_file file_path, disposition: "inline"
    else
      # --- ЗАЩИТА ОТ БЕСКОНЕЧНОГО ЦИКЛА ---
      # Если не найден САМ файл index.html, не делаем редирект на него же.
      # Вместо этого отправляем пользователя на главную страницу всего сайта.
      if safe_filename == "index.html"
        redirect_to root_path, alert: "Главная страница Смешариков временно недоступна."
      else
        # Если не найден любой другой файл (картинка, видео),
        # перенаправляем на главную страницу проекта Смешариков.
        redirect_to "/smeshariki/index.html"
      end
    end
  end
end
