require "json"
require "open-uri"
require "nokogiri"

def get_cities_html
  open("cities.txt") do |file|
    file.readlines.each do |city|
      puts city.chomp
      open("https://ja.wikipedia.org/wiki/#{URI.encode(city.chomp)}") do |resource|
        open("data/#{city.chomp}.html", "w+") do |output|
          output.puts(resource.read)
        end
      end
    end
  end
end

def parse_cities_html
  data = []
  Dir.glob("data/*.html") do |entry|
    open(entry) do |file|
      doc = Nokogiri::HTML.parse(file.read, nil, "UTF-8")
      
      text = doc.xpath("//*[text()=\"所在地\"]")[0].parent().text()
      puts text
      if text =~ /北緯(\d+)度(\d+)分(.+)秒東経(\d+)度(\d+)分(.+)秒/
        latitude = $1.to_f + $2.to_f / 60 + $3.to_f / (60 * 60)
        longitude = $4.to_f + $5.to_f / 60 + $6.to_f / (60 * 60)
        key = entry.sub(/data\/(.+).html$/, '\1')
        data << {
          "name" => key,
          "longitude" => longitude,
          "latitude" => latitude
        }
      end
    end
  end
  open("saitama-cities.json", "w+") do |file|
    json = {
      "name" => "埼玉県",
      "cities" => data
    }
    file.puts(JSON.generate(json))
  end
end

parse_cities_html
