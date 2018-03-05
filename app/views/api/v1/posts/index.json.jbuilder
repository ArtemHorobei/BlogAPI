json.data do
  json.posts do
    json.array!(@posts) do |post|
      json.call(post, :id, :user_id, :title, :image, :content)
      json.first_name post.user.first_name
      json.last_name post.user.last_name
    end
  end
end
