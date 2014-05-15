$:.unshift "."
require 'sinatra'
require "sinatra/reloader" if development?
require 'sinatra/flash'
require 'pl0_program'
require 'auth'
require 'pp'

enable :sessions
set :session_secret, '*&(^#234)'
set :reserved_words, %w{grammar test login auth}
set :max_files, 9       # no more than max_files+1 will be saved

helpers do
  def current?(path='/')
    (request.path==path || request.path==path+'/') ? 'class = "current"' : ''
  end
end


get '/grammar' do
  erb :grammar
end

get '/' do
  users = User.all
  programs = []
  
  i = 0
  length = users.length
  if users.length != 0
    while i < length && i < settings.max_files
      user = users.sample
      programs.concat([aux.username])
      users.delete(user)
      i += 1
    end
  end
  
  source = "VAR A;
PROCEDURE FUNCION(VAR B); A = 0;."
  erb :index, 
      :locals => { :programs => programs, :source => source, :user => "" }
end

get '/:user?/:file?' do |user,file|
  u = User.first(:username => user)
  
  if !u
    flash[:notice] =
	%Q{<div class="error">Usuario "#{user}" no encontrado.</div>}
    redirect to '/'
  end
  
  programs = u.pl0programs
  c = programs.first(:name => file)
  
  if !c
    flash[:notice] = 
      %Q{<div class="error">Fichero "#{file}" no encontrado. </div>}
    redirect to '/'
  end
  
  source = c.source
  erb :index, 
      :locals => { :programs => programs, :source => source, :user => '/' + u.username + '/' }
end

get '/:user?' do |user|
  u = User.first(:username => user)
  
  if !u
    flash[:notice] =
	%Q{<div class="error">Usuario "#{user}" no encontrado.</div>}
    redirect to '/'
  end
  
  programs = u.pl0programs
  source = ""
  
  erb :index, 
      :locals => { :programs => programs, :source => source, :user => u.username + '/' }
end

get '/:selected?' do |selected|
  user = User.first(:username => selected)
  puts user
  if !user
    flash[:notice] =
	%Q{<div class="error">Usuario "#{selected}" no encontrado.</div>}
    redirect to '/'
  end
    
  programs = user.pl0programs
  c = programs[0]
  source = if c then c.source else "var a;
procedure funcion(var b); b=0;." end

  erb :index, 
      :locals => { :programs => programs, :source => source, :user => user.username }
end

post '/save' do
  pp params
  name = params[:fname]
  if session[:auth] # authenticated
    if settings.reserved_words.include? name  # check it on the client side
      flash[:notice] = 
        %Q{<div class="error">No se puede guardar el fichero con nombre '#{name}'.</div>}
      redirect back
    else 
      #Comprobamos si un usuario existe
      user = User.first(:username => session[:email])
      if !user
	flash[:notice] = 
	    %Q{<div class="error">El usuario '#{session[:email]}' no existe en la base de datos.</div>}
	redirect to '/'
      end
      pp user
      c  = user.pl0programs.first(:name => name)
      if c
        c.source = params["input"]
        c.save
      else
        if Pl0program.all.size >= settings.max_files
          c = Pl0program.all.sample
          c.destroy
        end
        c = Pl0program.create(
          :name => params["fname"], 
          :source => params["input"])
	user.pl0programs << c
      end
      user.save
      flash[:notice] = 
        %Q{<div class="success">Fichero guardado como #{c.name} por #{session[:name]}.</div>}
      redirect to '/' + user.username + '/' + name
    end
  else
    flash[:notice] = 
      %Q{<div class="error">Usted no se ha autenticado.<br />
         Identifíquese con Google o Github.
         </div>}
    redirect back
  end
end

class String
  def name
    to_str
  end
end
