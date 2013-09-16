#!/usr/bin/ruby

require 'rubygems'
require 'term/ansicolor'

class String
  include Term::ANSIColor
end

puts "welcome to the drive indexer. press Ctrl+C an any point to kill me.".on_yellow.red.bold # startup message

drives = `ls -1 /Volumes`   # get all drives connected
drives = drives.split("\n") # seperate drives into array
puts "select drive:"    # drive select message

drives.each_with_index do |drive,id| # print list of drives
  puts "#{id}. #{drive}" # print id. drive name for each drive
end

did = gets.chomp.to_i # get id and convert it to a int
dn = drives[did]   # get drive by inputed id

puts "selected #{dn}" # tell user what drive they selected
puts "type any notes you have about this drive (type empty line to end notes):" # message about how to add notes
notes = gets.chomp # get first line of notes

while notes != ""  # if notes is empty dont try to get another line
  inp = gets.chomp # get another line from user
  if inp == ""      # if input in empty break
    break
  end
  notes += "_(n)_#{inp}" # append _(n)_ + input to notes _(n)_ will later be translated to a newline
end

dp = "/Volumes/#{dn}" # make a var with the path to the drive

curloc = File.expand_path(File.dirname(__FILE__)) # var with the absoloute path to the script

puts "starting indexing files " + "ignore any ".on_yellow.black +
      "Permission Denied".on_yellow.red + " etc. Errors".on_yellow.black # notify user that the script has started indexing
      
`cd "#{dp}" && find . \\( ! -regex '.*/\\..*' \\) -type f > "#{curloc}/files.tmp"` # run the command to put all the paths into a file
puts "done indexing. doing detailed sweep"

output = File.open("Listings/#{dn}.dindex", 'w') # open the output file

input = File.open("files.tmp") # open the temp file with the paths listed
linecount = `wc -l "#{curloc}/files.tmp"`
linecount = linecount[2..-("#{curloc}/files.tmp".length)].to_i
linenum = 0
puts "#{linecount} lines"

output.puts "#{dn}:::#{notes}" # print the header with the drive name and the notes to the output file

i = 0
input.each_line do |line| # loop over paths in temp file
  path = line[2..-2] # clip newline and ./ off path
  abspath = "/Volumes/#{dn}/#{path}"
  size = `wc -c "#{abspath}" 2> /dev/null` # get file size
  size = size[0..-(abspath.length + 3)].strip # clip indent and filename from command output
  statout = `stat -s "#{abspath}"` # get the output of stat
  if !statout.nil?
    stats = statout.split
    modify = stats[9].split('=')[1]
    create = stats[10].split('=')[1]
  else
    modify = "0000000000"
    create = "0000000000"
  end
  output.puts "#{path}:::#{create}:::#{modify}:::#{size}" # print path and data to output file
  percent_done = (linenum*100/linecount)
  print "\r                               \r#{'#'.red*i} #{' '*(50-i)} #{percent_done}%"
  if i == 50
    i = 0
  end
  i += 1
  linenum += 1
end
puts "\r done indexing #{dn} index can be located in #{curloc}/Listings/#{dn}.dindex"
input.close
output.close
File.delete("files.tmp") if File.exist?("files.tmp")
