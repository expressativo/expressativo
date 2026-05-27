class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    subscription = current_user.push_subscriptions.find_or_initialize_by(
      endpoint: subscription_params[:endpoint]
    )

    subscription.assign_attributes(
      p256dh: subscription_params[:p256dh],
      auth: subscription_params[:auth],
      user_agent: request.user_agent
    )

    if subscription.save
      head :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    endpoint = params[:endpoint] || params.dig(:push_subscription, :endpoint)
    subscription = current_user.push_subscriptions.find_by(endpoint: endpoint)
    subscription&.destroy
    head :no_content
  end

  private

  def subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh, :auth)
  end
end
