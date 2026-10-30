# Servidor de autorización OAuth 2.1 mínimo para clientes MCP (Claude Code,
# Claude Desktop, Cursor…). Flujo:
#
#   1. El cliente pega en /mcp, recibe 401 y lee /.well-known/oauth-protected-resource
#   2. Lee /.well-known/oauth-authorization-server
#   3. Se registra en /oauth/register (registro dinámico, sin estado: el
#      client_id es un mensaje firmado con el nombre y las redirect_uris)
#   4. Abre /oauth/authorize en el navegador → el usuario aprieta "Autorizar"
#   5. Canjea el código en /oauth/token (PKCE S256) por un CliAccessToken
class OauthController < ApplicationController
  before_action :authenticate_user!, only: %i[authorize grant deny]
  skip_before_action :process_pending_invitation, except: %i[authorize]
  skip_forgery_protection only: %i[register token]
  before_action :load_authorization_params, only: %i[grant deny]

  SESSION_KEY = "oauth_authorize_params".freeze
  CLIENT_VERIFIER_PURPOSE = "mcp_oauth_client".freeze

  # GET /.well-known/oauth-protected-resource(/mcp)
  def protected_resource
    render json: {
      resource: "#{request.base_url}/mcp",
      authorization_servers: [ request.base_url ],
      bearer_methods_supported: [ "header" ],
      resource_name: "Tivo"
    }
  end

  # GET /.well-known/oauth-authorization-server
  def metadata
    render json: {
      issuer: request.base_url,
      authorization_endpoint: oauth_authorize_url,
      token_endpoint: oauth_token_url,
      registration_endpoint: oauth_register_url,
      response_types_supported: [ "code" ],
      grant_types_supported: [ "authorization_code" ],
      code_challenge_methods_supported: [ "S256" ],
      token_endpoint_auth_methods_supported: [ "none" ],
      scopes_supported: [ "read", "write" ]
    }
  end

  # POST /oauth/register
  def register
    redirect_uris = Array(params[:redirect_uris]).map(&:to_s)
    if redirect_uris.empty? || !redirect_uris.all? { |uri| valid_redirect_uri?(uri) }
      return oauth_error("invalid_redirect_uri", "redirect_uris debe usar https o http://localhost.")
    end

    client_name = params[:client_name].to_s.strip.first(80).presence || "Cliente MCP"
    client_id = client_verifier.generate({ "name" => client_name, "redirect_uris" => redirect_uris })

    render json: {
      client_id: client_id,
      client_name: client_name,
      redirect_uris: redirect_uris,
      grant_types: [ "authorization_code" ],
      response_types: [ "code" ],
      token_endpoint_auth_method: "none"
    }, status: :created
  end

  # GET /oauth/authorize
  def authorize
    client = decode_client(params[:client_id])
    redirect_uri = params[:redirect_uri].to_s

    if client.nil? || !client["redirect_uris"].include?(redirect_uri)
      return redirect_to root_path, alert: "Solicitud de autorización inválida (cliente o redirect_uri desconocidos)."
    end

    unless params[:response_type] == "code" && params[:code_challenge].present? && params[:code_challenge_method] == "S256"
      return redirect_with_error(redirect_uri, params[:state], "invalid_request")
    end

    @client_name = client["name"]
    @redirect_host = URI.parse(redirect_uri).host
    session[SESSION_KEY] = {
      "client_name" => @client_name,
      "redirect_uri" => redirect_uri,
      "state" => params[:state].to_s,
      "code_challenge" => params[:code_challenge].to_s
    }
  end

  # POST /oauth/authorize
  def grant
    code = CliAuthorizationCode.create!(
      user: current_user,
      redirect_uri: @authorization["redirect_uri"],
      code_challenge: @authorization["code_challenge"],
      code_challenge_method: "S256"
    )
    session.delete(SESSION_KEY)
    redirect_to append_query(@authorization["redirect_uri"], code: code.raw_code, state: @authorization["state"]),
                allow_other_host: true
  end

  # POST /oauth/deny
  def deny
    session.delete(SESSION_KEY)
    redirect_with_error(@authorization["redirect_uri"], @authorization["state"], "access_denied")
  end

  # POST /oauth/token
  def token
    return oauth_error("unsupported_grant_type", "Solo se admite authorization_code.") unless params[:grant_type] == "authorization_code"
    return oauth_error("invalid_request", "Falta code_verifier (PKCE).") if params[:code_verifier].blank?

    client = decode_client(params[:client_id])
    code = CliAuthorizationCode.consume!(params[:code], verifier: params[:code_verifier])

    if code.nil? || code.code_challenge.blank? || code.redirect_uri != params[:redirect_uri].to_s
      return oauth_error("invalid_grant", "El código es inválido, expiró o ya fue usado.")
    end

    access_token = CliAccessToken.create!(user: code.user, name: "MCP · #{client&.dig('name') || 'Cliente MCP'}")
    response.headers["Cache-Control"] = "no-store"
    render json: { access_token: access_token.raw_token, token_type: "Bearer", scope: access_token.scopes }
  end

  private

  def client_verifier
    Rails.application.message_verifier(CLIENT_VERIFIER_PURPOSE)
  end

  def decode_client(client_id)
    client_verifier.verified(client_id.to_s)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
    nil
  end

  def load_authorization_params
    @authorization = session[SESSION_KEY]
    return if @authorization.is_a?(Hash) && @authorization["redirect_uri"].present?

    redirect_to root_path, alert: "La solicitud de autorización expiró. Volvé a intentar desde tu cliente MCP."
  end

  def valid_redirect_uri?(uri)
    parsed = URI.parse(uri)
    return false if parsed.host.blank? || parsed.fragment.present?

    parsed.scheme == "https" || (parsed.scheme == "http" && CliAuthorizationCode::ALLOWED_HOSTS.include?(parsed.host))
  rescue URI::InvalidURIError
    false
  end

  def redirect_with_error(redirect_uri, state, error)
    redirect_to append_query(redirect_uri, error: error, state: state.presence), allow_other_host: true
  end

  def append_query(uri, values)
    separator = uri.include?("?") ? "&" : "?"
    "#{uri}#{separator}#{values.compact.to_query}"
  end

  def oauth_error(error, description)
    render json: { error: error, error_description: description }, status: :bad_request
  end
end
