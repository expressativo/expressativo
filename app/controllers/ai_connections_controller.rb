# Guía para conectar Tivo con Claude u otros clientes MCP, y lista de
# aplicaciones conectadas (con opción de revocar).
class AiConnectionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @mcp_url = mcp_url
    @connected_apps = current_user.cli_access_tokens.active.order(last_used_at: :desc, created_at: :desc)
  end
end
