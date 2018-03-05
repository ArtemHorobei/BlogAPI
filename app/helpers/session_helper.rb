module SessionHelper

  def update_sessions
    if @resource && @client_id
      CacheRedactor.update_sessions(@resource.id, @client_id)
    end
  end

  # user auth
  def set_user_by_token_helper(mapping=nil)
    # determine target authentication class
    rc = resource_class(mapping)

    # no default user defined
    return unless rc

    #gets the headers names, which was set in the initialize file
    uid_name = DeviseTokenAuth.headers_names[:'uid']
    access_token_name = DeviseTokenAuth.headers_names[:'access-token']
    client_name = DeviseTokenAuth.headers_names[:'client']
    provider_name = DeviseTokenAuth.headers_names[:'provider']

    # parse header for values necessary for authentication
    uid        ||= request.headers[uid_name] || params[uid_name]
    @token     ||= request.headers[access_token_name] || params[access_token_name]
    @client_id ||= request.headers[client_name] || params[client_name]
    provider   ||= request.headers[provider_name] || params[provider_name] || 'email'

    # client_id isn't required, set to 'default' if absent
    @client_id ||= 'default'

    # check for an existing user, authenticated via warden/devise, if enabled
    if DeviseTokenAuth.enable_standard_devise_support
      devise_warden_user = warden.user(rc.to_s.underscore.to_sym)
      if devise_warden_user && devise_warden_user.tokens[@client_id].nil?
        @used_auth_by_token = false
        @resource = devise_warden_user
        @resource.create_new_auth_token
      end
    end

    # user has already been found and authenticated
    return @resource if @resource && @resource.class == rc

    # ensure we clear the client_id
    if !@token
      @client_id = nil
      return
    end

    return false unless @token

    # mitigate timing attacks by finding by uid instead of auth token
    if provider == 'maximarkets'
      user = uid && rc.find_by(uid: uid, provider: provider)
    else
      user = uid && rc.where(uid: uid).where.not(email: nil, provider: 'maximarkets').first
    end

    if user && user.valid_token?(@token, @client_id)
      # sign_in with bypass: true will be deprecated in the next version of Devise
      if self.respond_to? :bypass_sign_in
        bypass_sign_in(user, scope: :user)
      else
        sign_in(:user, user, store: false, bypass: true)
      end
      return @resource = user
    else
      # zero all values previously set values
      @client_id = nil
      return @resource = nil
    end
  end
end
