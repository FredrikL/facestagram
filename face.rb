require 'sinatra'
require 'haml'
require 'datamapper'
require './itemrepo'

configure do
  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/face.db")
  DataMapper.finalize
  DataMapper.auto_upgrade!
end

get '/' do
  @images = ItemRepo.new.with_face

  haml :face
end

get '/db' do
  new_items = ItemRepo.new.sync_all_locations

  "done, with #{new_items} new items"
end