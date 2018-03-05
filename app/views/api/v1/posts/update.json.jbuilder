json.data do
  json.post do
    json.call(@post, :id, :user_id, :quote, :market, :recommend,
              :price, :access, :content, :forecast, :created_at, :updated_at)
    json.author_name @post.user.name
    json.author_avatar @post.user.return_avatar 'large'
    json.author_avatar_medium @post.user.return_avatar 'medium'
    json.author_avatar_small @post.user.return_avatar 'small'
    json.image @post.return_image 'large'
    json.image_medium @post.return_image 'medium'
    json.image_small @post.return_image 'small'
    json.image_sizes @post.image_dimensions
    json.views_count UniqueViews.post_view_count(@post.id)
    json.likes_count @post.like_count(@post.id)
    json.comments_count @post.comments.count
    json.liked @post.liked?(current_user.id, @post.id)
    if @post.group_id
      json.group_name Group.find_by(id: @post.group_id).name
      json.group_id @post.group_id
    end
    if @post.company_id
      json.company_name Company.find_by(id: @post.company_id).name
      json.company_id @post.company_id
    end
    if !@post.meta_tags.nil?
      json.meta do
        json.call(@post.meta_tags, :meta_title, :meta_description, :meta_image, :meta_link, :meta_video)
      end
    end
    json.created_at_long @post[:created_at].to_i
    json.updated_at_long @post[:updated_at].to_i
    json.forecast_long @post[:forecast].to_i
    json.collaborators do
      json.array! @post.users do |user|
        json.id user.id
        json.avatar user.image
        json.name user.return_name
        json.confirmed @post.collaborators.find_by(user_id: user.id).confirmed
      end
    end
    json.manage_post do
      if current_user.posts.include?(@post)
        json.can_delete current_user.posts.include?(@post)
      elsif @post.company_id
        company_user = @post.get_company_user(current_user)
        json.can_delete !company_user.nil? && !company_user.role.include?('user')
      elsif @post.group_id
        group_user = @post.get_group_user(current_user)
        json.can_delete  !group_user.nil? && !group_user.role.include?('user')
      end
      json.can_update current_user.posts.include?(@post)
    end
    if !@post.file_links.nil?
      json.files do
        @post.file_links.each do |post_file|
          json.set! post_file.title do
            json.call(post_file, :document, :title)
          end
        end
      end
    end
    if @post.expired?
      json.expired_bars @post.expired_bars
      json.profitability if @post.profitability != nil
    end
  end
end