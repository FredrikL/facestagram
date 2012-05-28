require 'open-uri'
require 'json'
require 'datamapper'
require 'pp'

INSTAGRAM_KEY = ''
FACE_KEY = ''
FACE_SECRET = ''

class ItemRepo
  def with_face
    # return with face, grouped by location

    items = Hash.new
    Location.all.each do |loc|
      items[loc.name] =  Item.all(:limit => 5, :location_name => loc.name, :face => true, :order => [:created_at.desc])
    end

    items
  end

  def sync_all_locations
    locs = Location.all
    sum = 0
    locs.each do |loc|
      sum += sync_locations loc
    end

    sum
  end

  def sync_locations loc
    if(loc.long.empty? and loc.lat.empty?) then
      jsn = open("https://api.instagram.com/v1/media/popular?access_token=#{INSTAGRAM_KEY}").read
    else
      jsn = open("https://api.instagram.com/v1/media/search?lat=#{loc.lat}&lng=#{loc.long}&access_token=#{INSTAGRAM_KEY}&distance=5000").read
    end

    p = JSON.parse(jsn)

    images = p["data"].map do |itm| 
      item = Item.first_or_create(:url => itm["images"]["low_resolution"]["url"].to_s) 
      item.item_url = itm["link"]
      item.location_name = loc.name
      item.save
      item
    end

    images.select!{|i| i.face == false && (i.created_at > (DateTime.now - (3))) }
    return 0 if images.length < 1

    # face.com max input is 30 images per request
    urls = "http://api.face.com/faces/detect.json?api_key=#{FACE_KEY}&api_secret=#{FACE_SECRET}&urls=" + images.take(25).map{|i| i.url}.join(",")
    fjsn = open(urls).read
    f = JSON.parse(fjsn)

    f["photos"].select!{|face| face["tags"].length > 0 }

    # valdate result from face.com, only include +50% confidence
    images.select! do |i|
      (f["photos"].select do |face| 
        face["tags"][0]["attributes"]["face"]["confidence"].to_i > 50 and face["url"] == i.url 
      end).length > 0
    end

    images.each do |i| 
      i.update(:face => true)
    end

    return images.length
  end
end

class Item
  include DataMapper::Resource

  property :url, String, :length => 200,:key => true
  property :item_url, String, :length => 200
  property :face, Boolean, :default => false
  property :created_at, DateTime
  belongs_to :location
end

class Location
  include DataMapper::Resource

  property :name, String, :key => true
  property :long, String
  property :lat, String
end