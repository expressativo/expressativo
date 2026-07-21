class Api::V1::CliTokenController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [ :create ]

  # POST /api/v1/cli_token
  # Body: { code: "...", code_verifier: "...", redirect_uri: "...", client_name: "tivo-cli (host)" }
  def create
    code_record = CliAuthorizationCode.consume!(
      params[:code],
      verifier: params[:code_verifier]
    )

    if code_record.nil?
      render json: { error: "invalid_grant", message: "El código de autorización es inválido, expiró o ya fue usado." },
             status: :unprocessable_entity
      return
    end

    token = CliAccessToken.create!(
      user: code_record.user,
      name: token_name
    )

    render json: {
      access_token: token.raw_token,
      token_type: "Bearer",
      expires_in: nil,
      user: {
        id: token.user.id,
        email: token.user.email,
        first_name: token.user.first_name,
        last_name: token.user.last_name
      }
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "server_error", message: e.record.errors.full_messages.to_sentence },
           status: :internal_server_error
  end

  private

  def token_name
    user_agent = request.user_agent.to_s
    host_part = params[:client_name].presence || user_agent.presence || "unknown"
    "tivo-cli · #{host_part[0..60]}"
  end
end
