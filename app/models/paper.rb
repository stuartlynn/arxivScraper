class Paper 
  include MongoMapper::Document
  
  key :title , String
  key :arxiv_no, String, :required=>true
  key :abstract, String 
  key :authors, Array 
  key :parsed, Boolean, :default => false 
  
  timestamps!
  
  has_many :assets
  
  before_destroy :remove_assets
  
  def parse 
    self.parse_meta
    self.parse_paper
  end
  
  def abs_url
    "http://arxiv.org/abs/#{self.arxiv_no}"
  end
  
  def pdf_url
    "http://arxiv.org/pdf/#{self.arxiv_no}"
  end

  def ps_url
    "http://arxiv.org/ps/#{self.arxiv_no}"
  end
  
  def extra_url
    "http://arxiv.org/e-print/#{self.arxiv_no}"
  end
  
  def api_url
    "http://export.arxiv.org/api/query?id_list=#{self.arxiv_no}"
  end
  
  def local_url
    "tmp/papers/#{self.arxiv_no}/"
  end
  
  def parse_paper
    unless self.parsed
      self.get_paper
      Dir.glob("#{self.local_url}/*.tex") do |file|
        ` lib/tralics-2.13.6-macintel #{file} --output_dir #{self.local_url}`
      end
    
      Dir.glob("#{self.local_url}/*.xml") do |xml_file|
        paper = Hpricot(IO.read(xml_file))
      
        self.extract_tables(paper)
        self.extract_figs(paper)
      end
      self.parsed=true
      self.save
    end
  end
  
  def extract_tables(paper)

    tables=paper.search("//table").each do |table|
      caption = table.search("head").inner_html.gsub(/<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)<\/\1>/i, "").gsub(".","")
      rows  = table.search("row")
      puts "table title is #{title}"

      breaks = table.search("error[@n*='tableline']")

      data = rows.map do |row|
        row.search("cell").map do |cell|
           cell.inner_html.gsub(/<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)<\/\1>/i, "")
        end
      end
      
      puts "#{data.class}"
      
      self.assets<< Asset.new(:kind=>"table",:data=>data, :caption=>caption)
    end
    
    self.save
  end
  
  def extract_figs(data)
    figures = data.search("//figure")

    figures.each do |figure|
      puts
      puts "figure #{figure.to_s}"
      puts
      number = figure.attributes["id-text"]
      file   = figure.attributes["file"]
      caption = figure.search("head").inner_html
      ext = figure.attributes["extension"]
      unless file.empty? or ext.empty?
        self.assets<< Asset.new(:kind=>"figure", :caption=>"caption.html_safe", 
                              :file=>File.open("#{self.local_url}/#{file}.#{ext}","r"),
                              :number=>number.html_safe)
      end
    end
    
  end
  
  def delete_files
    `rm #{self.local_url}`
  end
  
  
  def get_paper 
    `mkdir #{self.local_url}`
    `cd #{self.local_url}`
    puts "getting archive from #{self.extra_url}"
    `curl #{self.extra_url} >> #{self.local_url}/paper.tar.gz`
    `tar xzvf #{self.local_url}/paper.tar.gz -C #{self.local_url}/`
  end
  
  def parse_meta
    puts("grabbing from #{self.abs_url}")
    page = Hpricot(RestClient.get(self.api_url))
    self.title = page.search("title")[1].html
    self.abstract = page.at("summary").html
    self.authors = page.search("name").map{|a| a.html}

    self.save
  end
  
  
  def remove_assets
    self.assets.delete_all
  end
  
  
end