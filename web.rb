require 'sinatra/base'
require 'rest_client'
require 'compass'
require 'bootstrap-sass'
require 'json'

class MhealthCodeGetter < Sinatra::Base
  enable :sessions
  set :public_folder, File.join(File.dirname(__FILE__), 'static')
  
  get '/' do
    haml :index
  end
  
  post '/code' do
    key = params[:consumer_key]
    secret = params[:consumer_secret]
    scope = params[:scope]
    redirect_uri = request.url
    
    escaped_redirect_uri = CGI.escape redirect_uri
    
    authorization_url = "https://mhealth.att.com/auth?client_id=#{key}&response_type=code&redirect_uri=#{escaped_redirect_uri}&scope=#{scope}"
    
    session[:redirect_uri] = redirect_uri
    session[:key] = key
    session[:secret] = secret
    session[:scope] = scope
    
    redirect authorization_url
  end
  
  get '/code' do
    halt 420 unless params[:code]
    code = params[:code]
    
    key = session[:key]
    secret = session[:secret]
    
    auth_code_url = "https://#{key}:#{secret}@mhealth.att.com/access_token.json"
    response = RestClient.post(auth_code_url, grant_type: 'authorization_code', code: code, redirect_uri: session[:redirect_uri])
    
    access_token = JSON.parse(response)['access_token']
    
    haml :code, locals: {code: access_token, scope: session[:scope], key: session[:key]}
  end
  
  get '/stuff.css' do
    sass :stuff
  end
end