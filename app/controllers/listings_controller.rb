class ListingsController < ApplicationController
  def view
    begin
      @listing = Listing.find(params[:id])
    rescue
      @listing = Listing.active.where({slug:params[:slug]}).first
    end
    if @listing
      @page_title = 'View Job - ' + @listing.title
      @page_description = @listing.description
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def start
    @page_title = 'Post a Job - Start'
    @listing = Listing.new
    @listing.category_id = Category.asc(:name).first._id;
    @company = Company.new
    
    respond_to do |format|
      format.html # start.html.erb
      format.json { render json: @listing }
    end
  end

  def preview
    @page_title = 'Post a Job - Preview'
    #raise params.inspect
    @listing = Listing.new(params[:listing])
    temp_slug = slug = @listing.title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    count = 1;
    while Listing.active.where({slug:slug}).count > 0
      count += 1;
      slug = "#{temp_slug}-#{count.to_s}";
    end

    @listing.slug = slug
    @listing.company = Company.new(params[:company])
    @listing.company.logo = nil

    if params[:company][:logo]
      @listing.company.logo = Moped::BSON::Binary.new(:generic, params[:company][:logo].read);
      #raise @listing.company.logo.data
    end

    @stripe = BootStripe.new;
    @stripe.price_in_cents = 2500
    @stripe.item_description = "Premium Ad ($25.00)"

    session[:listing] = @listing

    @company = Company.new(params[:company])
    respond_to do |format|
      if @listing.valid?
        format.html # preview.html.erb
        format.json { render json: @listing }
      else
        @company = @listing.company
        format.html { render action: "start" }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end

    end
  end

  class BootStripe
    attr_accessor :price_in_cents, :item_description
    def public_key
      if (ENV["RAILS_ENV"].eql?("production"))
        "pk_live_n4U0gtoLg1OHxiDgxIzmktME"
      else
        "pk_test_6ZwiMDWrWaPmtoK14yivUQCU"
      end
    end

    def private_key
      if (ENV["RAILS_ENV"].eql?("production"))
        "sk_live_0eyMLnRRBKa0WqQMBuwEd77D"
      else
        "sk_test_y3UPtBJpKyUy96TS3NeJIBTe"
      end
    end
  end

  def publish_prem
    token = params[:stripeToken]
    @listing = session[:listing]
    @listing.payment_token = token;
    @listing.is_premium = true;

    respond_to do |format|
      if @listing.save
        Stripe.api_key = BootStripe.new.private_key

        # Create the charge on Stripe's servers - this will charge the user's card
        begin
          charge = Stripe::Charge.create(
              :amount => 2500, # amount in cents, again
              :currency => "usd",
              :card => token,
              :description => @listing.company.email
          )

          @listing.price_paid = 25.00
          @listing.paid_utc = Time.now.utc
          @listing.save

          if (ENV["RAILS_ENV"].eql?("production"))
            begin
              tweet @listing
              ListingMailer.confirm_listing(@listing).deliver
            rescue Exception => e
              return redirect_to @listing.get_url, notice: e.message.to_s
            end
          end

          format.html { redirect_to @listing.get_url, notice: 'Congratulations! Your credit card has been charged. Your listing is live for 30 days. If you have any questions, please email us at admin@workdistributed.com' }
          format.json { render json: @listing, status: :created, location: @listing }
        rescue Stripe::CardError => e
          # The card has been declined
          flash[:error] = e.message
          format.html { render action: "preview" }
          format.json { render json: @listing.errors, status: :unprocessable_entity }
        end
      else
        format.html { render action: "preview" }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  def publish
    @listing = session[:listing]
    @listing.price_paid = 0.00
    @listing.paid_utc = Time.now.utc

    respond_to do |format|
      if @listing.save
        if (ENV["RAILS_ENV"].eql?("production"))
          begin
            tweet @listing
            ListingMailer.confirm_listing(@listing).deliver
          rescue Exception => e
            return redirect_to @listing.get_url, notice: e.message.to_s
          end
        end

        format.html { redirect_to @listing.get_url, notice: 'Congratulations! Your listing is live for 30 days. If you have any questions, please email us at admin@workdistributed.com' }
        format.json { render json: @listing, status: :created, location: @listing }
      else
        format.html { render action: "preview" }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  def tweet listing
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "ngrFHdlVTE4YMOoJtXbrXkx9J"
      config.consumer_secret     = "80i6Wve22Eokyb5KKim5GfkICzz2eCRk5r9WIW4wTlPRNjYsEx"
      config.access_token        = "2577253417-xojSyXw79hsLjNcaw4NdPSaDtnaDZW0XnIwygHr"
      config.access_token_secret = "5nnVLH5dFfmTlNCDzKLDFDwsGsi34VqoYVb02F4o4urJR"
    end

    if (ENV["RAILS_ENV"].eql?("production"))
      begin
        greetings = ["Yo!", "Psst!", "Ooh!", "Ho ho!", "Hey,", "Inconceivable!", "Sweet!", "Ack!", "Aha!", "Whoa!", "Cool!", "Guess what?", "Announcement:", "Great Odin's raven!", "Check it out:", "News flash!", "Oh boy!"]
        hiringWords = ["summoning up", "seeking", "on a quest to find", "scouting out", "hunting for", "looking for", "hiring", "in dire need of", "searching for", "willing to pay cold, hard cash for", "scanning the horizon for", "actively seeking"]

        client.update "#{greetings.sample} #{listing.company.name} is #{hiringWords.sample} a #{listing.category.name}: #{listing.get_url} #remotejobs #workdistributed"
      rescue
        # not sure what to do here. probably need an ErrorEmailer at some point to report these...
      end

    end
  end
end