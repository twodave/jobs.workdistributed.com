class ListingMailer < ActionMailer::Base
  default from: 'noreply@jobs.workdistributed.com'
  def confirm_listing(listing)
    @listing = listing;
    mail(to: @listing.company.email, subject: "Job Confirmation for: #{@listing.title}")
  end
end