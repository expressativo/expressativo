module Admin
  class UsersController < BaseController
    def index
      @total_count = User.count
      @active_count = User.active.count
      @users = User.order(Arel.sql("current_sign_in_at IS NULL"), current_sign_in_at: :desc, created_at: :desc)
    end
  end
end
