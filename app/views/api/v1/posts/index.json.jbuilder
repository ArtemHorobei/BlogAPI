json.data do
  json.posts do
    json.array!(@posts) do |post|
      json.call(post, :id, :user_id, :title, :image, :content)
      json.author_name post.user.name
    end
  end
end
