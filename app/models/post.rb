class Post < ActiveRecord::Base
  validates :content,
            format: { with: /\A\z|(?!&nbsp;.*)\A([\S])+([\s]*.+)*\z/},
            length: { maximum: 63206 },
            allow_nil: true
  belongs_to :user
  def create_post_file(file, key)
    self.file_links.create(title: file['title'], document: upload_post_file(file['document'], S3_BUCKET_FILES_NAME, key))
  end
end