class BaseController < ApplicationController
  include Concerns::Users::SetUserByToken
  before_action :authenticate_user!

  private

  def authenticate_user!
    unless current_user
      return render json: {
          error_token: true
      }, status: 401
    end
  end

  def current_user
    @current_user ||= set_user_by_token(:'user')
  end
end
