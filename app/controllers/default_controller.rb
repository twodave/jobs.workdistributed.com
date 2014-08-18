class DefaultController < ApplicationController
  def index
    @page_title = "Remote Jobs, No Recruiters"
    @categories = Category.all
    @listsum = 0;
    @categories.each{|c|@listsum += c.listing_count}
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @examples }
    end
  end
end
