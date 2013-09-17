#!/usr/bin/ruby

#require './lib.rb'
#require './File'
#require './Drive'
require './database'
require 'sqlite3'
require 'date'
require 'filesize'

# def printFile(file)
#   format = "%a %b %d, %I:%M %p"
#   creation =         Time.at(file.creation).to_datetime.strftime(format)
#   modification = Time.at(file.modification).to_datetime.strftime(format)
#   size = 
#   puts "File, #{row.path} is #{row.size} and was created at #{creation} and last modified on #{modification} on drive #{row.drive.name}"
# end
# 

def printable(file)
 # puts self.inspect
  attrs = OpenStruct.new
  format = "%a %b %d, %I:%M %p"
  attrs.creation =         Time.at(file.creation).to_datetime.strftime(format)
  attrs.modification = Time.at(file.modification).to_datetime.strftime(format)
  attrs.size = Filesize.from("#{file.size} B").pretty
  attrs.path = file.path
  attrs.id = file.id
  attrs.drive_id = file.drive_id
end

def confirm(message)
  print "#{message} (y/n): "
  gets.chomp.upcase.include? "Y"
end

def split_no_whitespace(array,splitter)
  if RUBY_VERSION.split('.')[0].to_i >= 2
    return array.split(splitter).map(%:strip:)
  else
    return array.split /\s*#{splitter}\s*/
  end
end

def getDateTime(message)
  
end

findParams = {}

if confirm("enter keywords?")
  puts "enter keywords seperated by ',':"
  keywords = split_no_whitespace(gets.chomp,',')
  findParams[:path_keywords] = keywords
end

if confirm("enter a filename?")
  puts "enter the filename you are looking for (% matches any number of characters, _ matches one)"
  filename = gets.chomp
  findParams[:path_filename] = filename
end

if confirm "enter an extension?"
  puts "enter a ext"
  ext = gets.chomp
  findParams[:path_ext] = ext
end



resp = Files.findAll(findParams)
resp.each do |row|
  puts row.path
end

=begin
resp.each do |row|
  prnt = row.printable
  puts %Q{File:
  ID:           #{prnt.id}
  Path:         #{prnt.path}
  Creation:     #{prnt.creation}
  Modification: #{prnt.modification}
  Size:         #{prnt.size}
  Drive ID:     #{prnt.drive_id}
  Drive Name:   #{prnt.drive.name}
  Drive Notes:
    #{prnt.drive.notes.gsub("\n","\n    ")}
  }
end
=end
#printable(resp).inspect
# 
# resp.each do |row|
#   format = "%a %b %d, %I:%M %p"
#   creation =         row.creation.strftime(format)
#   modification = row.modification.strftime(format)
#   drive = row.drive
#   puts "File, #{row.path} is #{row.size} and was created at #{creation} and last modified on #{modification} on drive #{drive.name}"
# end
# 
# drive = DriveSearch.find_id(1)
# 
# drive.files.each do |file|
#   puts "#{file.path}"
# end