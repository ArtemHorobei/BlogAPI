json.data do
  json.call(@resource, :id, :provider, :uid, :email, :lasted_at, :created_at, :image, :background_image, :updated_at, :email, :first_name, :last_name, :nickname, :name, :view_mode)
  json.language @resource.language
  json.is_nickname @resource.is_nickname
  json.created_at_long @resource[:created_at].to_i
  json.updated_at_long @resource[:updated_at].to_i
  json.lasted_at_long @resource[:lasted_at].to_i
end
