#!/usr/bin/ruby

require "./lib.rb"
require "net/https"
require "uri"
require 'yaml'
require 'term/ansicolor'

class String
  include Term::ANSIColor
end

def download(path,filename)  
  `curl -#f -o "#{filename}" --url "#{path}"`
end

config = YAML.load_file("appdata.yaml")

uriPrefix = config["webPrefix"]
uri = URI.parse(uriPrefix + "/list.php")
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)

response = http.request(request)

srvbody = response.body

srvfiles = srvbody.split('<br/>')

versions = srvfiles.map { |f|
  x = f[0..-3].to_f
}

if versions.max > config["version"]
  puts "UPDATING FROM v#{config['version']} TO v#{versions.max}".on_yellow.red
  puts "DOWNLOADING UPDATE"
  
  download("#{uriPrefix}/#{versions.max}.rb","TEMP.rb")
  
  puts "INSTALLING UPDATE"
  File.delete("update.log") if File.exist?("update.log")
  if !system("/bin/bash -c 'ruby TEMP.rb &> >(tee -a update.log >&1)'")
    puts "ERROR INSTALLING UPDATE, LOOK IN 'update.log' to see info".on_red.white
  else
    config["version"] = versions.max
    File.write('appdata.yaml',config.to_yaml)
  end
  
  File.delete("TEMP.rb") if File.exist?("TEMP.rb")
else
  puts "ALREADY UP TO DATE".on_yellow.red
end