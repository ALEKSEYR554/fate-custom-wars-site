class CoronaController < ApplicationController
  def serve
    requested_path = params[:filename]
    base_dir = Rails.root.join("storage", "corona_files").to_s
    file_path = File.expand_path(File.join(base_dir, requested_path))

    if file_path.start_with?(base_dir) && File.exist?(file_path) && !File.directory?(file_path)

      # 1. Готовим базовые настройки отдачи файла
      options = { disposition: "inline" }

      # 2. Если запрашивают страницу (.htm или .html):
      # - Явно указываем тип text/html (чтобы браузер не скачивал её)
      # - Указываем кодировку Shift_JIS (чтобы иероглифы отображались без кракозябр)
      if requested_path.end_with?(".htm", ".html")
        options[:type] = "text/html"# ; charset=Shift_JIS"
      end

      # Отдаем файл с настроенными заголовками
      send_file file_path, options
    else
      if requested_path != "index.html"
        redirect_to "/corona/index.html"
      else
        render plain: "Файл index.html проекта Корона не найден в storage/corona_files/", status: :not_found
      end
    end
  end
end
