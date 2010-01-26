#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require 'daemons'
require 'net/ftp'
require 'ruby-growl'

class Grabby
  def initialize
    @config = YAML.load_file(File.join(File.dirname(__FILE__), "grabby.yml"))
  end

  def run
    Dir.chdir(@config["path"])

    Dir[@config["pattern"]].each do |f|
      file_name = "#{get_guid}#{File.extname(f)}"

      Net::FTP.open(@config["ftp"]["host"], @config["ftp"]["username"], @config["ftp"]["password"]) do |ftp|
        ftp.passive = true
        ftp.chdir(@config["ftp"]["path"])
        ftp.putbinaryfile(f, file_name)
      end

      `printf #{@config["url"]}#{file_name} | pbcopy`

      File.delete(f)
      
      notify("Giddyup! File uploaded!")
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
  
  def notify(message)
    growl = Growl.new("localhost", "Grabby says...", ["Upload Notification"])
    growl.notify("Upload Notification", "Grabby", message)
  rescue
    # do nothing
  end
end

g = Grabby.new

Daemons.run_proc("grabby.rb") do
  g.run_and_sleep
end