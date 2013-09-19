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
    group_id = params[:group_id]
    scope = params[:scope]
    redirect_uri = request.url

    query_params = {
      client_id: key,
      response_type: 'code',
      redirect_uri: redirect_uri,
      scope: scope,
    }
    # optionals
    query_params[:ownership_key] = '_'
    query_params[:provider_key] = group_id unless group_id.nil? || group_id.empty?

    authorization_url = "https://mhealth.att.com/auth?#{URI.encode_www_form(query_params)}"

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
