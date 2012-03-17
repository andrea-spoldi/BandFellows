require 'data_mapper'
require 'carrierwave'
require 'carrierwave/datamapper'
require 'carrierwave/processing/mini_magick'
require 'mini_magick'
#require 'rmagick'

#CarrierWave.configure do |config| 
#  config.root = "#{Dir.pwd}/public/" 
#end 

DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.db")

class MyUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    File.join('public','images')
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  version :thumb do
    process :resize_to_fill => [80,80]
  end
  storage :file
end

class User
  include DataMapper::Resource
	property :id, Serial
	property :name, String, :required => true
	mount_uploader :file, MyUploader
end

class Category
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :content, Text, :required => true
  has n, :posts, :constraint => :destroy
end

class Post
  include DataMapper::Resource

  property :id, Serial
  property :content, Text, :required => true
  property :topic, String, :required => true
  property :email, String, :required => false
  property :created_at, DateTime
  mount_uploader :file, MyUploader
  belongs_to :category
  has n, :comments, :constraint => :destroy
end


class Comment
  include DataMapper::Resource

  property :id, Serial
  property :content, Text, :required => true
  property :topic, String, :required => false
  property :email, String, :required => false
  property :created_at, DateTime
  mount_uploader :file, MyUploader
  belongs_to :post
end

=begin
class Image
  include DataMapper::Resource

  property :id, Serial

  mount_uploader :file, MyUploader
  belongs_to :comment
  belongs_to :post
end
=end

DataMapper.finalize.auto_upgrade!

