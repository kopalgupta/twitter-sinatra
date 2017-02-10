require 'sinatra'
require 'data_mapper'

DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/data.db")

set :sessions, true
set :bind, '0.0.0.0'

class User
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :email, String
	property :password, String
	property :handle, String
end

class Tweet
	include DataMapper::Resource
	property :id, Serial
	property :content, String
	property :user_id, Integer
	property :handle, String
end

class Upvote
	include DataMapper::Resource
	property :id, Serial 
	property :tweet_id, Integer
	property :user_id, Integer
end

class Comment
	include DataMapper::Resource
	property :id, Serial
	property :tweet_id, Integer
	property :user_id, Integer
	property :content, String
	property :handle, String
end


DataMapper.finalize
User.auto_upgrade!
Tweet.auto_upgrade!
Upvote.auto_upgrade!
Comment.auto_upgrade!

get '/' do
	user = nil
	if session[:user_id] 
		user = User.get(session[:user_id])
	else
		redirect '/signin'
	end

	tweets = Tweet.all
	upvotes = Upvote.all
	comments = Comment.all
	erb :index , locals: {:user => user, :tweets => tweets, :upvotes => upvotes, :comments => comments}
end

get '/signup' do
	erb :signup
end

post '/signup' do
	name = params[:name]
	email = params[:email]
	password = params[:password]
	handle = params[:handle]

	user = User.all(:handle => handle).first

	if user
		redirect '/signup'
	else
		user = User.new
		user.name = name
		user.email = email
		user.password = password
		user.handle = handle
		user.save
		session[:user_id] = user.id
		redirect '/'
	end
end

get '/signin' do
	erb :signin
end

post '/signin' do
	handle = params[:handle]
	password = params[:password]

	user = User.all(:handle => handle).first

	if user
		if user.password == password
			session[:user_id] = user.id
		else
			redirect '/signin'
		end
	else
		redirect '/signup'
	end

	redirect '/'
end

post '/logout' do
	session[:user_id] = nil
	redirect '/'
end

# get '/my_tweets' do
# end

post '/add_tweet' do
	content = params[:content]
	tweet = Tweet.new
	tweet.content = content
	tweet.user_id = session[:user_id]
	tweet.handle = User.get(session[:user_id]).handle
	tweet.save
	redirect '/'
end

post '/delete_tweet' do 
	tweet = Tweet.get(params[:delete])
	tweet.destroy
	redirect '/'
end

get '/upvote/:tweet_id' do 
	upvote = Upvote.all(:tweet_id => params[:tweet_id], :user_id => session[:user_id]).first
	if !upvote
		upvote = Upvote.new
		upvote.tweet_id = params[:tweet_id]
		upvote.user_id = session[:user_id]
		upvote.save
	else
		upvote.destroy
	end
	redirect '/'
end

post '/comment/:tweet_id' do 
	content = params[:content]
	comment = Comment.new
	comment.content = content
	comment.user_id = session[:user_id]
	comment.tweet_id = params[:tweet_id]
	comment.handle = User.get(session[:user_id]).handle
	comment.save
	redirect '/'
end

post '/delete_comment' do 
	comment = Comment.get(params[:delete])
	comment.destroy
	redirect '/'
end
