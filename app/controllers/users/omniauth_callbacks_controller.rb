class Users::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController

  include SessionHelper

  after_action :update_sessions, only: [:omniauth_success]

  def omniauth_success
    if auth_hash[:info][:email].blank?
      render json: { errors: I18n.t("sign_in_social.EMAIL_IS_EMPTY") },
             status: :unprocessable_entity
    else
      super
    end
  end

  protected

  def get_resource_from_auth_hash
    @resource = resource_class.where(email: auth_hash[:info][:email]).first_or_initialize

    identity = Identity.where(uid: auth_hash['uid'],
                              provider: auth_hash['provider'],
                              registration_platform: request.host).first_or_initialize

    @resource.identities << identity if identity.new_record?
    @resource.uid = identity.uid
    @resource.provider = identity.provider
    if @resource.new_record?
      @oauth_registration = true
      set_random_password
    end
    # sync user info with provider, update/generate auth token
    assign_provider_attrs(@resource, auth_hash)

    @resource.name =  "#{@resource.return_name}"
    #Elastic servise update data
    User.find_by(id: @resource.id).reindex(:search_data)

    # assign any additional (whitelisted) attributes
    extra_params = whitelisted_params
    @resource.assign_attributes(extra_params) if extra_params

    @resource
  end

  def assign_provider_attrs(user, auth_hash)
    user.assign_attributes(
      email:      auth_hash['info']['email']
    )
    if auth_hash[:provider] == 'facebook' && auth_hash[:info][:image][0, 5] == 'http:'
      user.assign_attributes(image: 'https:' + auth_hash[:info][:image].from(5) + '?type=large') unless user.image
      user.assign_attributes(first_name: auth_hash[:info][:first_name]) unless user.first_name
      user.assign_attributes(last_name: auth_hash[:info][:last_name]) unless user.last_name
    else
      user.assign_attributes(image: auth_hash[:info][:image] + '?type=large') unless user.image
      user.assign_attributes(first_name: auth_hash[:info][:first_name]) unless user.first_name
      user.assign_attributes(last_name:  auth_hash[:info][:last_name]) unless user.last_name
    end
  end
end