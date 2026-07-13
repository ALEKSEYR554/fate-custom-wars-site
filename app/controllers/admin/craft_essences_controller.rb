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
        redirect_to admin_craft_essences_path, notice: "Карта #{@ce.name} обновлена!"
      else
        render :edit
      end
    end
  end
end
