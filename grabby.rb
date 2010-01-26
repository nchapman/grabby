require 'rubygems'
require 'yaml'
require 'daemons'
require 'net/ftp'

class Grabby
  def initialize
    @config = YAML.load_file("grabby.yml")
  end

  def run
    Dir.chdir(@config["path"])

    Dir["#{@config["prefix"]}*"].each do |f|
      begin
        file_name = "#{get_guid}#{File.extname(f)}"

        Net::FTP.open(@config["ftp"]["host"], @config["ftp"]["username"], @config["ftp"]["password"]) do |ftp|
          ftp.passive = true
          ftp.chdir(@config["ftp"]["path"])
          ftp.putbinaryfile(f, file_name)
        end

        `printf #{@config["url"]}#{file_name} | pbcopy`

        `growlnotify -n Grabby -t "Grabby says..." -m "Giddyup\! File uploaded\!"`

        File.delete(f)
      rescue
        `growlnotify -n Grabby -t "Grabby exclaims..." -m "File wasn't uploaded\! Check your settings\!"`
      end
    end
  end

  def run_and_sleep
    loop do
      run
      sleep(1)
    end
  end
  
  def get_guid
    chars = ("A".."Z").to_a + ("a".."z").to_a + ("0".."9").to_a

    guid = ""

    6.times { guid += chars[rand(chars.size)] }

    return guid
  end
end

g = Grabby.new

Daemons.run_proc("grabby.rb") do
  g.run_and_sleep
end