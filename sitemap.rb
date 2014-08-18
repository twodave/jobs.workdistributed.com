require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = 'https://jobs.workdistributed.com'
SitemapGenerator::Sitemap.create do
  add '/', :changefreq => 'daily', :priority => 0.9
  add '/listings/start', :changefreq => 'daily', :priority => 0.8

  Listing.active.each do |l|
    add "/#{l.slug}", :changefreq=>'daily', :priority => 0.8
  end
end
SitemapGenerator::Sitemap.ping_search_engines # Not needed if you use the rake tasks