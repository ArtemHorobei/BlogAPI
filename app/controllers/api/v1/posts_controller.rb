class Api::V1::PostsController < BaseController

  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  def index
    @posts = Post.all
    if @errors
      render json: {errors: @errors}, status: 422
    else
      render :index
    end
  end

  def show
    @post = Post.accessible_by(current_ability).find_by(id: params[:id])
    if @post
      @user = @post.user
      @liked = current_user ? @post.liked?(current_user.id, @post.id) : false
      render :show, status: :ok
    else
      render json: { errors: 'Post not found' }, status: :not_found
    end
  end

  def create
    @post = current_user.posts.new(create_post_params)
    if @post.valid?
      @post.save!
      render :create, status: :created
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @post
    if @post.soft_delete
      delete_chart(@post) if @post.market != 'Simple'
      @post.delete_notifications
      head(:ok)
    else
      head(:unprocessable_entity)
    end
  end

  private

  def create_post_files
    @post_files.each{ |file|
      key = file[0]
      file_content = file[1]
      @post.create_post_file( file_content, key ) if @allow_content_types.include?(file_content['content_type'])
    }
  end

  def find_post
    @post = Post.find_by(id: params[:id])
  end

  def find_post_files
    @allow_content_types = ['text/plain', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/vnd.oasis.opendocument.text', 'application/vnd.oasis.opendocument.spreadsheet', 'application/vnd.oasis.opendocument.text-template', 'application/vnd.oasis.opendocument.spreadsheet-template', 'application/vnd.oasis.opendocument.text-template', 'application/vnd.oasis.opendocument.spreadsheet-template', 'application/vnd.oasis.opendocument.text', 'application/vnd.oasis.opendocument.spreadsheet']
    @post_files = params[:post][:files].as_json
  end

  def show_post
    current_user.followers.each do |follower|
      publisher.publish(@post, follower)
    end
  end

  def create_post_params
    params.require(:post).permit(:title, :content)
  end
end
