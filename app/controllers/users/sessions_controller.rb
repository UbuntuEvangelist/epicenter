class Users::SessionsController < ApplicationController
  before_action :redirect_if_logged_in

  def new
  end

private

  def redirect_if_logged_in
    redirect_to after_sign_in_path_for(current_user) if current_user
  end
end
