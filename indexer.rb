#!/usr/bin/ruby

require './lib.rb'
require 'sqlite3'
require 'term/ansicolor'
class String
  def quote
    self.gsub(/[']/, "\'\'")
  end
end

def format_time (timeElapsed)

  @timeElapsed = timeElapsed

  #find the seconds
  seconds = @timeElapsed % 60

  #find the minutes
  minutes = (@timeElapsed / 60) % 60

  #find the hours
  hours = (@timeElapsed/3600)

  #format the time

  return hours.to_s + ":" + format("%02d",minutes.to_s) + ":" + format("%02d",seconds.to_s)
end
driveid = 0
fileid = 0
begin
  db = SQLite3::Database.new "index.sqlite"
  gline = ""
  ln = 0
  db.execute "drop table if exists Drive"
  db.execute "drop table if exists File"
  db.execute "create table if not exists Drive(id INTEGER PRIMARY KEY , name VARCHAR(100), notes TEXT);"
  db.execute "create table if not exists File(id INTEGER PRIMARY KEY , drive_id INTEGER,\
   path TEXT, creation INTEGER, modification INTEGER, size INTEGER);"
  linenum = 1
  linecount = `wc -l compiled.cdindex`
  linecount = linecount[2..-18].to_i
  roundlen = 1000
  starttimer = roundlen
  timerbegining = Time.now
  timeperround = 0
  File.open("compiled.cdindex", "r") do |file|
    file.each_line do |line|
      
      if starttimer == 0
        timeperround = Time.now - timerbegining
        timerbegining = Time.now 
        starttimer = roundlen 
      end
      
      gline = line
      if line[-2] == "{"
        driveid += 1
        ln = 1
        linesplit = line[0..-3].split(":::")
        if linesplit[1].nil?
          puts "please update your drive indexes."
        end
        dn = linesplit[0]
        notes = linesplit[1]
        db.execute "insert into Drive (id,name,notes) values ('#{driveid}','#{dn.quote}','#{notes.quote}');"
      elsif line[-2] == "}"
        
      else
        fileid += 1
        ln = 2
        linesplit = line.split(":::")
        path = linesplit[0]
        creation = linesplit[1]
        modification = linesplit[2]
        size = linesplit[3][0..-1]
        db.execute "insert into File (id, path, drive_id,creation,modification,size)\
         values ('#{fileid}', '#{path.quote}', '#{driveid}', '#{creation}', '#{modification}', '#{size}');"
      end 
      timeleft = ((linecount-linenum)*(timeperround))/roundlen
      timeformatted = format_time timeleft.round
      percent_done = (linenum*100/linecount)
      print "\r#{percent_done}% #{linenum} of #{linecount} approx #{timeformatted} left or #{timeleft} seconds                       "
      $stdout.flush
      linenum += 1
      starttimer -= 1
    end
  end
rescue SQLite3::Exception => e
  print "ERR:"
  puts e
  puts ln
  puts gline
  puts gline.quote
ensure
  db.close if db
end