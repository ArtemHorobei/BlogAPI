class Users::SessionsController < DeviseTokenAuth::SessionsController
  include SessionsDoc
  include LocaleHelper
  include SessionHelper

  before_action :set_locale
  before_action :authenticate_user!, only: [:keep_alive]
  after_action :update_sessions, only: [:create, :sign_in_social]

  def create
    # Check
    field = (resource_params.keys.map(&:to_sym) & resource_class.authentication_keys).first

    @resource = nil
    if field
      q_value = resource_params[field]

      if resource_class.case_insensitive_keys.include?(field)
        q_value.downcase!
      end

      q = "#{field.to_s} = ? AND provider='email'"

      if ActiveRecord::Base.connection.adapter_name.downcase.starts_with? 'mysql'
        q = "BINARY " + q
      end

      @resource = resource_class.find_by(email: q_value)
      @resource.update(provider: 'email', uid: q_value) if @resource
    end

    if @resource && valid_params?(field, q_value) && (!@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?)
      valid_password = @resource.valid_password?(resource_params[:password])
      if (@resource.respond_to?(:valid_for_authentication?) && !@resource.valid_for_authentication? { valid_password }) || !valid_password
        render_create_error_bad_credentials
        return
      end
      create_token_info
      set_token_on_resource
      # create
      @resource.save

      sign_in(:user, @resource, store: false, bypass: false)

      yield @resource if block_given?

      render :create, status: :ok
    elsif @resource && !(!@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?)
      render_create_error_not_confirmed
    else
      render_create_error_bad_credentials
    end
  end

  def keep_alive
    RedisPostsCache.prolong_expire(@client_id)
    CacheRedactor.update_sessions(current_user.id, @client_id)
    render json: {status: :ok}
  end

  def sign_in_social
    provider_params = params[:provider]
    if !provider_params
      render_provider_is_required
      return
    end
    token = params[:access_token]
    if !token
      render_token_is_required
      return
    end
    provider_class = get_provider(provider_params)
    if !provider_class
      render_provider_not_found
      return
    end
    attributes = provider_class.get_fields_by_token(token)
    if attributes['error']
      render_invalid_token
      return
    end
    if !attributes['email']
      render_email_is_empty
      return
    end
    @resource = User.where(email: attributes['email']).first_or_initialize
    identity = Identity.where(uid: attributes['email'],
                              provider: provider_params,
                              registration_platform: request.host).first_or_initialize
    @resource.identities << identity if identity.new_record?
    @resource.uid = identity.uid
    @resource.provider = identity.provider
    if @resource.new_record?
      @oauth_registration = true
      set_random_password
      assign_provider_attrs(@resource, attributes)
      @resource.name =  "#{@resource.first_name} #{@resource.last_name}"
    end
    create_token_info
    set_token_on_resource
    create_auth_params
    if resource_class.devise_modules.include?(:confirmable)
      # don't send confirmation email!!!
      @resource.skip_confirmation!
    end
    sign_in(:user, @resource, store: false, bypass: false)
    @resource.save!
    User.find_by(id: @resource.id).reindex(:search_data)
    yield @resource if block_given?
    render :create, status: :ok
  end

  private
  def get_provider(provider_params)
    case provider_params
      when 'facebook'
        provider_class = Facebook
      else
        provider_class = nil
    end
    provider_class
  end

  def set_random_password
    # set crazy password for new oauth users. this is only used to prevent
    # access via email sign-in.
    p = SecureRandom.urlsafe_base64(nil, false)
    @resource.password = p
    @resource.password_confirmation = p
  end

  def create_auth_params
    @auth_params = {
        auth_token:     @token,
        client_id: @client_id,
        uid:       @resource.uid,
        expiry:    @expiry,
        config:    @config
    }
    @auth_params.merge!(oauth_registration: true) if @oauth_registration
    @auth_params
  end

  def set_token_on_resource
    @resource.tokens[@client_id] = {
        token: BCrypt::Password.create(@token),
        expiry: @expiry,
        config: @config
    }
  end

  def create_token_info
    # create token info
    @client_id = SecureRandom.urlsafe_base64(nil, false)
    @token     = SecureRandom.urlsafe_base64(nil, false)
    @expiry    = (Time.now + DeviseTokenAuth.token_lifespan).to_i
    @config    = nil
  end

  def assign_provider_attrs(user, attributes)
    user.assign_attributes(
        first_name: attributes['first_name'],
        last_name:  attributes['last_name'],
        email:      attributes['email'],
        image:      "https://graph.facebook.com/#{attributes['id']}/picture?type=large"
    )
  end

  def render_provider_not_found
    render json: {
        errors: [I18n.t("sign_in_social.PROVIDER_NOT_FOUND")]
    }, status: 404
  end

  def render_token_is_required
    render json: {
        errors: [I18n.t("sign_in_social.PROVIDER_NOT_FOUND")]
    }, status: 404
  end

  def render_invalid_token
    render json: {
        errors: [I18n.t("sign_in_social.TOKEN_INVALID")]
    }, status: 404
  end

  def render_provider_is_required
    render json: {
        errors: [I18n.t("sign_in_social.PROVIDER_PARAMS_REQUIRED")]
    }, status: 422
  end

  def render_email_is_empty
    render json: {
        errors: [I18n.t("sign_in_social.EMAIL_IS_EMPTY")]
    }, status: 422
  end

end
