module Admin
  class CraftEssencesController < BaseController
    def index
      @ces = CraftEssence.order(:game_id)
    end

    def edit
      @ce = CraftEssence.find_by!(game_id: params[:game_id])
    end

    def update
      @ce = CraftEssence.find_by!(game_id: params[:game_id])
      if @ce.update(params.require(:craft_essence).permit(:name, :effect, :is_personal))
        schedule_backup("ces")
        redirect_to admin_craft_essences_path, notice: "Карта #{@ce.name} обновлена!"
      else
        render :edit
      end
    end

    def backup_telegram
      force_backup("ces")

      redirect_to admin_servants_path, notice: "Таймеры сброшены. Бэкап формируется и сейчас придет в Telegram."
    end
  end
end
