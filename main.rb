# dev hint: shotgun login.rb

require 'rubygems'
require 'sinatra'
require 'rest-client'
require 'json'
require 'rack-flash'
#require 'lib/auth/auth.rb'

class Main < Sinatra::Base

use Rack::Flash
#use Auth
enable :sessions

#helpers do
#  def logged_in?(user)
#        token = User.get_token(user)
#        request.cookies[user] == token
#  end 
#  def protected!
#        redirect '/login' unless logged_in?(session[:user])
#  end
#end


configure do
  set :public_folder, Proc.new { File.join(root, "static") }
end

get '/' do
#	protected!
#	@title = 'shop'
#	@sidebar = 'side'   
#	erb 'ciao'
	redirect :login
end

get '/register' do
	erb :register
end

post '/register' do
  u = User.new(:name => params[:name], :file => params[:image])
  redirect '/'
end


get '/login' do
	erb :login
end

get '/logout' do
        @name = session[:user] 
	response.set_cookie(@name, nil)
	session[:user] = nil
redirect '/'
end

end
