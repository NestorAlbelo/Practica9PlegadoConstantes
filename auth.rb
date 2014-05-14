require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
require 'omniauth-github'

use OmniAuth::Builder do # 
  config = YAML.load_file 'config/config.yml'
  provider :google_oauth2, config['identifier'], config['secret']
  config = YAML.load_file 'config/configG.yml'
  provider :github, config['identifier'], config['secret']
end

get '/auth/:name/callback' do
  session[:auth] = @auth = request.env['omniauth.auth']
  session[:name] = @auth['info'].name
  session[:image] = @auth['info'].image
  session[:email] = @auth['info'].email
  
  PP.pp @auth.methods.sort
  
  flash[:notice] = 
      %Q{<div class="success">Acceso concedido a #{@auth['info'].email}.</div>}

  if !User.first(:username => session[:email])
    user = User.create(:username => session[:email])
    user.save
  end
  
  redirect '/'
end

get '/auth/failure' do
  flash[:notice] = 
      params[:message] 
  redirect '/'
end