json.data do
  json.posts do
    json.array!(@posts) do |post|
      json.call(post, :id, :user_id, :title, :image, :content)
      json.author_name post.user.name
      json.author_avatar post.user.return_avatar 'large'
      json.author_avatar_medium post.user.return_avatar 'medium'
      json.author_avatar_small post.user.return_avatar 'small'
      json.image post.return_image 'large'
    end
  end
end
