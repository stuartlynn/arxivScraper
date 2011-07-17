class AssetsController < ApplicationController
  respond_to :json, :xml, :csv
  
  def show
    asset= Asset.find(params[:id])
    respond_with asset
  end
end