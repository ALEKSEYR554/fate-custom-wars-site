module Content
  class ContentController < ApplicationController
    def serve_video
      # 1. Берем имя файла из URL (например, "intro.mp4")
      # File.basename мы используем для БЕЗОПАСНОСТИ, чтобы хакеры не могли
      # передать путь вида "../../../etc/passwords" и скачать системные файлы
      safe_filename = File.basename(params[:filename])


      # 2. Формируем полный путь к файлу на компьютере/сервере
      # Rails.root указывает на главную папку твоего проекта
      file_path = Rails.root.join("storage", "placeholders", "videos", safe_filename)

      # 3. Проверяем, существует ли файл
      if File.exist?(file_path)
        # 4. Отдаем файл!
        send_file file_path,
                  type: "video/mp4",
                  disposition: "inline"
      else
        # Если файла нет, возвращаем ошибку 404
        render plain: "Файл не найден", status: :not_found
      end
    end
    def serve_random_video
      expires_now
      # 1. Находим все файлы с расширением .mp4 в нашей папке
      # Dir.glob возвращает массив абсолютных путей ко всем подходящим файлам
      video_pattern = Rails.root.join("storage", "placeholders", "videos", "*.mp4")
      videos = Dir.glob(video_pattern)

      # 2. Проверяем, есть ли там вообще видео
      if videos.any?
        # sample — это встроенный метод Ruby, который выбирает случайный элемент из массива
        random_video_path = videos.sample

        # 3. Отдаем случайный файл
        send_file random_video_path, type: "video/mp4", disposition: "inline"
      else
        render plain: "Файл не найден", status: :not_found
      end
    end
  end
end
