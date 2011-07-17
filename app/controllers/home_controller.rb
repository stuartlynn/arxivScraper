class HomeController < ApplicationController
  
  def index
    
  end
  
  def scrape
    redirect_to "/papers/#{params[:paper_id]}"
  end
end
