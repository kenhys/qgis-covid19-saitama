require "json"
require "csv"

class SaitamaCovid19StatsGenerator
  def initialize
    load_cities
    load_jokyo
  end

  def load_cities
    open("saitama-cities.json") do |file|
      @cities = JSON.load(file.read)["cities"]
    end
  end

  def city_name_to_long_lat(name)
    hash = @cities.collect do |city|
      next if city["name"] != name
      {longitude: city["longitude"], latitude: city["latitude"]}
    end
    hash.compact.first
  end
  
  def recoverd?(data)
    data["現状"] == "退院"
  end

  def recoverd_date(no)
    @recoverd_date[no].strftime("%Y-%m-%d")
  end

  def path2date(path)
    File.basename(path) =~ /(\d+)\.utf8\.csv/
    DateTime.parse($1)
  end

  def load_jokyo
    p latest_csv
    @recoverd_date = {}
    CSV.foreach(latest_csv, headers: true) do |row|
      @recoverd_date[row[0]] = path2date(latest_csv)
    end
    Dir.glob("covid19-jokyo/*.utf8.csv").sort.reverse.each do |path|
      next if path == latest_csv
      p ">" + path
      CSV.foreach(path, headers: true) do |row|
        if recoverd?(row)
          @recoverd_date[row[0]] = path2date(path)
        end
      end
    end
  end

  def latest_csv
    Dir.glob("covid19-jokyo/*.utf8.csv").sort.last
  end
  
  def parse_csv(path)
    index = 1
    File.open("data.csv", "w+") do |file|
      file.puts "start,end,longitude,latitude,memo"
      # failed to parse No.67
      CSV.foreach(path, headers: true) do |row|
        data = []
        # row["No."] always returns nil
        if index < 5
          index += 1
          next
        end
        city = row["居住地"]
        if ["県内", "県外", "埼玉県外", "川口市外", "東京都"].include?(city) or city.nil?
          puts "Skip: No.#{row[0]} #{row[1]} #{row[2]} #{row[3]} <#{city}>"
          index += 1
          next
        end
        begin
          data << DateTime.parse(row["判明日"]).strftime("%Y-%m-%d")
        rescue
          index += 1
          next
        end
        location = city_name_to_long_lat(city)
        unless location
          puts row
          raise "location not found: <#{city}>"
        end

        data << recoverd_date(row[0])
        data << location[:longitude]
        data << location[:latitude]
        data << "#{city}#{row['年代']}#{row['性別']}#{row['現状']}"
        file.puts data.join(",")
      end
    end
  end

  def run
    parse_csv(latest_csv)
  end
end

generator = SaitamaCovid19StatsGenerator.new
generator.run

