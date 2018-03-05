json.data do
  json.post do
    json.call(@post, :id, :user_id, :title, :image, :content)
    # json.author_name @post.user.name
    # json.likes_count @post.like_count(@post.id)
    # json.comments_count @post.comments.count
    # json.liked @post.liked?(current_user.id, @post.id)
    # if !@post.meta_tags.nil?
    #   json.meta do
    #     json.call(@post.meta_tags, :meta_title, :meta_description, :meta_image, :meta_link, :meta_video)
    #   end
    # end
  end
end