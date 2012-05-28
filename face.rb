require 'sinatra'
require 'open-uri'
require 'json'
require 'haml'

INSTAGRAM_KEY = '3013351.f59def8.163f5d6766194349bb3944ffa266449a'
FACE_KEY = 'dd7ce3161dc32ae97a07c91f10263877'
FACE_SECRET = '787a2ee50bb9ba09ad809b65e74ab319'

get '/' do
  jsn = open("https://api.instagram.com/v1/media/popular?access_token=#{INSTAGRAM_KEY}").read
  p = JSON.parse(jsn)

  @images = p["data"].map{|itm| Item.new(itm["images"]["low_resolution"]["url"]) }

  urls = "http://api.face.com/faces/detect.json?api_key=#{FACE_KEY}&api_secret=#{FACE_SECRET}&urls=" + @images.take(25).map{|i| i.url}.join(",")
  fjsn = open(urls).read
  f = JSON.parse(fjsn)
  f["photos"].each do |p| 
    if p["tags"].length > 0 then
      img = @images.select{|i| i.url == p["url"]}
      if !img.nil? then
        img.first.face = true
      end
    end
  end

  @images.select!{|i| i.face}

  haml :face
end

class Item
  attr_accessor :url, :face

  def initialize(url)
    self.url = url
    self.face = false
  end
end