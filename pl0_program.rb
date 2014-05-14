require 'data_mapper'
# full path!
DataMapper.setup(:default, 
                 ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/database.db" )

class Pl0program
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :key => true
  property :source, String, :length => 1..1024

  belongs_to :user
end

class User
  include DataMapper::Resource
  
  property :username, String, :key => true
  
  has n, :pl0programs
end

DataMapper.finalize
DataMapper.auto_upgrade!


