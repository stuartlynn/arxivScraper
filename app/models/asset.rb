class Asset 
  include MongoMapper::Document
  plugin Joint

  key :kind , String
  key :data , Array 
  key :caption, String
  timestamps!


  attachment  :file

  belongs_to :paper
  
  def csv
    self.data.collect{|row| row.join(",")}.join("\n")
  end
  
end