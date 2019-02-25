require 'bundler/setup'
Bundler.require
require 'sinatra/reloader'
require 'open-uri'
require 'json'
require 'net/http'

require 'sinatra/activerecord'
require './models'

enable :sessions

helpers do
  def current_user
    User.find_by(id: session[:user])
  end
end

get '/' do
  @musics = Post.all
  erb :index
end

get '/search' do
  erb :search
end

post '/search' do
  uri = URI("https://itunes.apple.com/search")
  uri.query = URI.encode_www_form({
    term: params[:artist],
    method: "get",
    country: "JP",
    media: "music",
    limit: 20
  })
  res = Net::HTTP.get_response(uri)
  json = JSON.parse(res.body)
  @musics = json['results']
  erb :search
end

post '/new' do
  current_user.Post.create(
    artist: params[:artist],
    album: params[:album],
    track: params[:track],
    image_url: params[:image_url],
    sample_url: params[:sample_url],
    comment: params[:comment],
    user_name: current_user.name
  )
  redirect '/home'
end

get '/sign_up' do
  erb :sign_up
end

post '/sign_up' do
  user = User.create(
    user_name: params[:user_name],
    profile_url: params[:profile_url],
    password_digest: params[:password_digest]
  )
  if user.persisted?
    session[:user] = user.id
  end
  redirect '/'
end

post '/sign_in' do
  user = User.find_by(user_name: params[:user_name])
  if user && user.authenticate(params[:password_digest])
    session[:user] = user.id
  end
  redirect '/search'
end

get '/sign_out' do
  session[:user] = nil
  redirect '/'
end

get '/home' do
  @user = User.find(session[:user])
  @musics = Post.where(user_id: session[:user])
  erb :home
end

get '/edit/:id' do
  @music = Post.find(params[:id])
  erb :edit
end

post '/update/:id' do
  music = Post.find(params[:id])
  music.comment = params[:commnet]
  music.save
  redirect '/home'
end

get '/delete/:id' do
  music = Post.find(params[:id])
  music.destroy
  redirect '/home'
end