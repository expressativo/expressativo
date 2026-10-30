# Revoca el acceso de una app conectada (CLI o cliente MCP) desde el perfil.
class ConnectedAppsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    current_user.cli_access_tokens.find(params[:id]).revoke!
    redirect_to ai_connection_path, notice: "Acceso revocado.", status: :see_other
  end
end
