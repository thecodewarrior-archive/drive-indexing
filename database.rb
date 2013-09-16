require 'rubygems'
require 'bundler/setup' 
require 'active_record'
require 'yaml'
require 'logger'
require 'ostruct'
require 'filesize'


dbconfig = YAML::load(File.open("database.yaml"))
ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Base.logger = Logger.new(File.open("activerecord.log",'w'))

module ReadOnly
  def readonly?
    true
  end
  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end
end

class Drives < ActiveRecord::Base
  self.table_name = "Drive"
  include ReadOnly
  
  def notes=(notes)
    self[:notes] =  notes.gsub("\n","_(n)_")
  end
  def notes
    self[:notes].gsub("_(n)_","\n")
  end
  
  has_many :files , :class_name => "Files", :foreign_key => "drive_id"
end

class Files < ActiveRecord::Base
  self.table_name = "File"
  include ReadOnly
  
  def printable(dformat = "%a %b %d %Y, %I:%M %p")
    #puts self.inspect
    attrs = OpenStruct.new
    attrs.creation =         Time.at(self.creation).to_datetime.strftime(dformat)
    attrs.modification = Time.at(self.modification).to_datetime.strftime(dformat)
    attrs.size = Filesize.from("#{self.size} B").pretty
    attrs.path = self.path
    attrs.id = self.id
    attrs.drive_id = self.drive_id
    attrs.drive = self.drive
    attrs.self = self
    attrs
  end
  
  belongs_to :drive, :class_name => "Drives", :foreign_key => "drive_id"

end
