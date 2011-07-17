class Asset 
  include MongoMapper::Document
  plugin Joint

  key :kind , String
  key :data , Array 
  key :caption, String
  key :number , Integer 

  timestamps!


  attachment  :file

  belongs_to :paper
  
  def csv
    self.data.collect{|row| row.join(",")}.join("\n")
  end
  
  def path
    "/file_store/4e22cd0a052328afae000005" 
  end
end