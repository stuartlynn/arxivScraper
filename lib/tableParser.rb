require 'hpricot'



raw= IO.read("ms_apj_accepted_060711.xml")

paper = Hpricot(raw)
tableNo=0

keywords = paper.search("//keywords | error[@n*='keywords']")
puts "keywords #{keywords}"

tables=paper.search("//table").map do |table|
  title = table.search("head").inner_html.gsub(/<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)<\/\1>/i, "").gsub(".","").gsub(" ","_")
  rows  = table.search("row")
  puts "table title is #{title}"

  breaks = table.search("error[@n*='tableline']")
  
  data = rows.map do |row|
    row.search("cell").map do |cell|
       cell.inner_html.gsub(/<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)<\/\1>/i, "")
    end
  end
  

  File.open("#{tableNo}#{title}.csv","w") do |file|
     file.puts (data.collect{|row| row.join(", ")}).join("\n")
  end
  tableNo+=1
  
  
  
  data
end

figures = paper.search("//figure")
puts "have #{figures.count} figures"

figures.each do |figure|
  puts
  puts "figure #{figure.to_s}"
  puts
  number = figure.attributes["id-text"]
  file   = figure.attributes["file"]
  caption = figure.search("head").inner_html
  ext = figure.attributes["extension"]
  puts "figure #{number} #{file}.#{ext}"
  puts "caption #{caption}"
end



