require 'rubygems'
require 'bundler/setup' 
require 'active_record'
require 'yaml'
require 'logger'
require 'ostruct'
require 'filesize'


dbconfig = YAML::load(File.open("database.yaml"))
ActiveRecord::Base.establish_connection(dbconfig)
#logger = File.open("activerecord.log",'w')
logger = STDERR
ActiveRecord::Base.logger = Logger.new(logger)

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
  
  def self.findAll( \
              creation: nil, modification: nil, size_gt: nil, size_lt: nil,
              path_keywords: nil, path_filename: nil, path_ext: nil, drive_id: nil
  )
    conditions  = []
    arguments = {}

    unless path_keywords.blank?
      i = 0
      path_keywords.each do |keyword|
        conditions << "path LIKE :path_#{i}"
        arguments[:"path_#{i}"] = "%#{keyword}%"
        i += 1
      end
    end
    
    unless path_filename.blank?
      conditions << "path LIKE :filename"
      arguments[:filename] = "%/#{path_filename}.%"
    end

    unless path_ext.blank?
      conditions << "path LIKE :ext"
      arguments[:ext] = "%.#{path_ext}"
    end
    
    unless drive_id.blank?
      conditions << "drive_id = :drive_id"
      arguments[:drive_id] = drive_id
    end
    
    unless size_lt.blank?
      conditions << "size <= :size_high"
      arguments[:size_high] = size_lt
    end
    
    unless size_gt.blank?
      conditions << "size >= :size_low"
      arguments[:size_low] = size_gt
    end
    
    unless creation.blank? or creation.class.name != "Array" or creation.length < 2
      conditions << "creation BETWEEN :creation_start AND :creation_end"
      arguments[:creation_start] = creation[0].to_f
      argumetns[:creation_end]   = creation[1].to_f
    end
    
    unless modification.blank? or modification.class.name != "Array" or modification.length < 2
      conditions << "modification“” BETWEEN :modification_start AND :modification_end"
      arguments[:modification_start] = modification[0].to_f
      argumetns[:modification_end]   = modification[1].to_f
    end

    all_conditions = conditions.join(' AND ')
    resp = self.where([all_conditions,arguments])
    
=begin old query
    options = {}
    querys =  []
    if !creation.nil?
      options[:c_start_date] = creation[0].to_f
      options[:c_end_date] =   creation[1].to_f
      querys << "creation >= :c_start_date AND creation <= :c_end_date"
    end
    if !modification.nil?
      options[:m_start_date] = modification[0].to_f
      options[:m_end_date] =   modification[1].to_f
      querys << "modification >= :m_start_date AND modification <= :m_end_date"
    end
    if !size_gt.nil?
      options[:size_low] =  size_gt
      querys << "size >= :size_low"
    end
    if !size_lt.nil?
      options[:size_high] = size_lt
      querys << "size <= :size_high"
    end
    if !path_keywords.nil?
      path_keywords.each_index do |id|
        options[:"p_keyword_#{id}"] = path_keywords[id]
        querys << "path LIKE \"%:p_keyword_#{id}%\""
      end
    end
    if path_filename != nil
      
    end
    if path_ext != nil
      
    end
    query = querys.join(" AND ")
    puts query.inspect
    puts options.inspect
    resp = self.where(query, options)
=end
    return resp
  end
    
  belongs_to :drive, :class_name => "Drives", :foreign_key => "drive_id"

end
