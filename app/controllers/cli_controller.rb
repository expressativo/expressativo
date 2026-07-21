class CliController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_authorize_params, only: %i[authorize]
  before_action :load_authorize_params, only: %i[grant]
  helper_method :client_label

  CLIENT_REGISTRY = {
    "tivo-cli" => {
      label: "Tivo CLI",
      image: nil
    }
  }.freeze

  SESSION_KEY = "cli_authorize_params".freeze

  def authorize
    # Guardamos los parámetros en sesión para que sobrevivan al login de Devise
    # y al POST del formulario de consentimiento.
    session[SESSION_KEY] = {
      "client_id" => @client_id,
      "redirect_uri" => @redirect_uri,
      "state" => @state,
      "code_challenge" => @code_challenge,
      "code_challenge_method" => @code_challenge_method
    }
  end

  def grant
    code = CliAuthorizationCode.new(
      user: current_user,
      redirect_uri: @redirect_uri,
      code_challenge: @code_challenge,
      code_challenge_method: @code_challenge_method
    )

    if code.save
      session.delete(SESSION_KEY)
      separator = @redirect_uri.include?("?") ? "&" : "?"
      redirect_to "#{@redirect_uri}#{separator}code=#{CGI.escape(code.raw_code)}&state=#{CGI.escape(@state)}",
                  allow_other_host: true
    else
      redirect_to root_path, alert: "No se pudo generar el código de autorización: #{code.errors.full_messages.to_sentence}"
    end
  end

  def deny
    session.delete(SESSION_KEY)
    redirect_to root_path, notice: "Autorización cancelada. Podés cerrar esta pestaña."
  end

  private

  def validate_authorize_params
    @client_id = params[:client_id].to_s
    @redirect_uri = params[:redirect_uri].to_s
    @state = params[:state].to_s
    @code_challenge = params[:code_challenge].presence
    @code_challenge_method = params[:code_challenge_method].presence || (@code_challenge.present? ? "S256" : nil)

    unless CLIENT_REGISTRY.key?(@client_id)
      redirect_to root_path, alert: "Cliente desconocido."
    end

    return if performed?

    unless valid_redirect_uri?(@redirect_uri)
      redirect_to root_path, alert: "redirect_uri inválido."
    end
  end

  def load_authorize_params
    stored = session[SESSION_KEY]

    unless stored.is_a?(Hash) && stored["state"].present?
      redirect_to root_path, alert: "La sesión de autorización expiró. Volvé a intentar desde la terminal."
      return
    end

    @client_id = stored["client_id"]
    @redirect_uri = stored["redirect_uri"]
    @state = stored["state"]
    @code_challenge = stored["code_challenge"]
    @code_challenge_method = stored["code_challenge_method"]

    # Validación de seguridad: si el formulario también envió estos valores,
    # deben coincidir con los guardados en sesión.
    if params[:state].present? && params[:state] != @state
      redirect_to root_path, alert: "El estado de autorización no coincide."
    end
  end

  def valid_redirect_uri?(uri)
    parsed = URI.parse(uri.to_s)
    parsed.scheme == "http" && %w[127.0.0.1 localhost].include?(parsed.host) && parsed.port.to_i.between?(1024, 65535)
  rescue URI::InvalidURIError
    false
  end

  def client_label
    CLIENT_REGISTRY[@client_id]&.dig(:label) || "una aplicación"
  end
end
