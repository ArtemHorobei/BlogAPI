class Users::PasswordsController < DeviseTokenAuth::PasswordsController
  include PasswordsDoc

  before_action :set_user_by_token, :only => [:update]
  skip_after_action :update_auth_header, :only => [:create, :edit]

  # this action is responsible for generating password reset tokens and
  # sending emails
  def create
    super
  end

  # this is where users arrive after visiting the password reset confirmation link
  def edit
    @resource = resource_class.reset_password_by_token(
        {reset_password_token: resource_params[:reset_password_token]})

    if @resource && @resource.id
      client_id  = SecureRandom.urlsafe_base64(nil, false)
      token      = SecureRandom.urlsafe_base64(nil, false)
      token_hash = BCrypt::Password.create(token)
      expiry     = (Time.now + DeviseTokenAuth.token_lifespan).to_i

      @resource.tokens[client_id] = {
          token:  token_hash,
          expiry: expiry
      }

      # ensure that user is confirmed
      @resource.skip_confirmation! if @resource.devise_modules.include?(:confirmable) && !@resource.confirmed_at

      # allow user to change password once without current_password
      @resource.allow_password_change = true;

      @resource.save!
      yield @resource if block_given?

      # give redirect value from params priority
      redirect_url = params[:redirect_url]

      # fall back to default value if provided
      redirect_url ||= DeviseTokenAuth.default_password_reset_url

      redirect_to(@resource.build_auth_url(redirect_url, {
          token:          token,
          client_id:      client_id,
          reset_password: true,
          config:         params[:config]
      }))
    else
      render_edit_error
    end
  end

  def update
    super
  end

end