class PapersController < ApplicationController
  respond_to :json, :xml, :csv
  
  def show
    puts params
    @paper = Paper.find_or_create_by_arxiv_no request.fullpath.split("/").last
    puts @paper.to_json
    @paper.parse unless @paper.parsed
  end
  
  
end