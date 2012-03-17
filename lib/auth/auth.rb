#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'dm-core'
require 'dm-migrations'
require 'json'
require 'carrierwave'
require 'carrierwave/datamapper'
require 'carrierwave/processing/mini_magick'
require 'mini_magick'


# connect DataMapper to a local SQLite file. 
# The SQLite database file can be found at /tmp/my_app.db
#DataMapper.setup(:default, ENV['DATABASE_URL'] || 
#    "sqlite3://#{File.join(File.dirname(__FILE__), '/tmp', 'my_app.db')}")
DataMapper.setup(:default, "sqlite3:users.db")
#######################################################################
#    Model Definitions
#######################################################################
class MyUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

configure do
  set :public_folder, Proc.new { File.join(root, "static") }
end

  def store_dir
    'images'
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
  
  property :id,             Serial
  property :username,       Text, :required => true
  property :password_hash,  Text
  property :password_salt,  Text
  property :name,	Text,	:required => true
  property :email, 	Text,	:required => true
  property :authToken,      Text
  mount_uploader :file, MyUploader 

  def guid
    "user/#{self.id}"
  end
  
  def self.create_user(json)
    salt      = [Array.new(6){rand(256).chr}.join].pack("m").chomp
    password  = encrypted_password(json['pwd'], salt)
    
    ret = { 
      :username => json['user'],
      :password_hash => password,
      :password_salt => salt,
      :name => json['name'],
      :email => json['email'], 
      :file => json['file']
    }
    ret 
  end
  
  def self.encrypted_password(hashed_password, salt) 
    string_to_hash = hashed_password + "My app is the best ever!" + salt 
    Digest::SHA256.hexdigest(string_to_hash)
  end

  def self.get_token(username)
     if username
	user = User.first(:username => username) 	
	if user
	token = user.authToken
	end
      else
 	token = false
     end
  end  
  def self.authenticate(username, password)
    if username && password
      user = User.first(:username => username)
      if user
        expected_password = encrypted_password(password, user.password_salt)
        if user.password_hash != expected_password
          user = nil 
        end
      end
    elsif password
      user = User.first(:authToken => password)
    else
      user = false
    end
    
    user
  end
  
end
#######################################################################
#    End Model Definitions
#######################################################################

# instructs DataMapper to setup your database as needed
DataMapper.auto_upgrade!

class Auth < Sinatra::Base
enable :sessions
use Rack::Session::Cookie

#get '/' do
#        @content = session[:name]
#	erb :index	
#end

#get '/hidden' do
#	protected!
#	@name = session[:user]
#	@content = User.get_token(@name)
#	erb :hidden
#end

post '/register' do
  ret   = Array.new
  jdata = {:name => params[:name],:user => params[:username],:pwd => params[:password],:email => params[:email], :file => params[:image]}.to_json
  data  = JSON.parse(jdata)
  halt(401, 'Could not parse') if data.nil?
  
  # See if the username already exists
  halt(401, 'User already exists') if User.first(:username => data['user'])
  
  opts = User.create_user(data) rescue nil
  halt(401, 'Invalid Format') if opts.nil?
  
  user = User.new(opts)
  halt(500, 'Could not register new user') unless user.save
  
  # Return guids of new records
  content_type 'application/json'
  response.status = 201  
  { 'content' => 'success' }.to_json
end

post '/login' do
  jdata = {:user => params[:username], :pwd => params[:password]}.to_json
  data      = JSON.parse(jdata)
  username  = data['user']
  password  = data['pwd']
  
  # If there is not an email or password/authKey then something is wrong
  halt(401, 'Invalid') if username.nil? && password.nil?
  
  user = User.authenticate(username, password)
  
  # Return new authToken
  content_type 'application/json'
  if user
    token         = Time.now.to_s + "My user is gettin' a new token" + user.password_salt
    hashed_token  = Digest::SHA512.hexdigest(token)
    
    user.authToken = hashed_token
    user.save
    
    response.status = 200
    session[:user] = user.username
    session[:name] = user.name
    #@cookie = session[:user]    
    @token = user.authToken
    response.set_cookie(session[:user], @token)
    #{ 'content' => hashed_token }.to_json
    redirect '/'
  else
    halt(401, 'Invalid login')
  end
end

end
