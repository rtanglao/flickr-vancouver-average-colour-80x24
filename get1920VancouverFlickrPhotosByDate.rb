#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'typhoeus'
require 'amazing_print'
require 'json'
require 'time'
require 'date'
require 'csv'
require 'logger'
require 'io/console'
require 'tzinfo'
require 'parseconfig'

def get_flickr_response(url, params, _logger)
  url = 'https://api.flickr.com/' + url
  try_count = 0
  begin
    result = Typhoeus::Request.get(
      url,
      params: params
    )
    x = JSON.parse(result.body)
  rescue JSON::ParserError => e
    try_count += 1
    if try_count < 4
      $stderr.printf("JSON::ParserError exception, retry:%d\n", try_count)
      sleep(10)
      retry
    else
      $stderr.printf("JSON::ParserError exception, retrying FAILED\n")
      x = nil
    end
  end
  x
end

logger = Logger.new($stderr)
logger.level = Logger::DEBUG

flickr_config = ParseConfig.new('flickr.conf').params
api_key = flickr_config['api_key']

if ARGV.length < 3
  puts "usage: #{$PROGRAM_NAME} yyyy mm dd"
  exit
end

tz = TZInfo::Timezone.get('America/Vancouver')
BEGIN_TIME = tz.local_time(ARGV[0].to_i, ARGV[1].to_i, ARGV[2].to_i, 0, 0)
END_TIME = tz.local_time(ARGV[0].to_i, ARGV[1].to_i, ARGV[2].to_i, 23, 59)
logger.debug "BEGIN: #{BEGIN_TIME.ai}"
logger.debug "END: #{END_TIME.ai}"

extras_str = 'description, license, date_upload, date_taken, owner_name, icon_server,' +
             'original_format, last_update, geo, tags, machine_tags, o_dims, views,' +
             'media, path_alias, url_sq, url_t, url_s, url_m, url_z, url_l, url_o,' +
             'url_c, url_q, url_n, url_k, url_h, url_b'

flickr_url = 'services/rest/'
first_page = true
photos_per_page = 0
number_of_pages = 0
csv_array = []
1.step(by: 1) do |page|
  logger.debug "page:#{page}"
  url_params =
    {
      method: 'flickr.photos.search',
      media: 'photos', # Just photos no videos
      content_type: 1, # Just photos, no videos, screenshots, etc
      api_key: api_key,
      format: 'json',
      nojsoncallback: '1',
      has_geo: 1,
      extras: extras_str,
      sort: 'date-taken-asc',
      page: page.to_s,
      # 15km radius from revolver :-)
      lat: "49.283166",
      lon: "-123.109331",
      radius: "15.0",
      min_taken_date: BEGIN_TIME.to_i.to_s,
      max_taken_date: END_TIME.to_i.to_s
    }
  photos_on_this_page = get_flickr_response(flickr_url, url_params, logger)
  if first_page
    first_page = false
    photos_per_page = photos_on_this_page['photos']['perpage'].to_i
    logger.debug "photos_per_page: #{photos_per_page}"
    number_of_pages = photos_on_this_page['photos']['pages'].to_i
  else
    logger.debug "photos_per_page: #{photos_per_page}"
  end
  logger.debug "STATUS from flickr API:#{photos_on_this_page['stat']} retrieved page:\
  #{photos_on_this_page['photos']['page'].to_i} of:\
  #{photos_on_this_page['photos']['pages'].to_i}"
  photos_on_this_page['photos']['photo'].each do |photo|
    logger.debug "woeid: #{photo['woeid']}"
    photo['id'] = photo['id'].to_i
    photo['description_content'] = photo['description']['_content']
    photo_without_nested_stuff = photo.except('description')
    csv_array.push(photo_without_nested_stuff)
  end
  break if page == number_of_pages # photos_on_this_page['photos']['pages']
  sleep 2
end
headers = csv_array[0].keys
logger.debug "number of photos: #{csv_array.length}"
logger.debug "FIRST photo: #{csv_array[0].ai}"
logger.debug "LAST photo: #{csv_array[-1].ai}"

FILENAME = format('%<yyyy>4.4d-%<mm>2.2d-%<dd>2.2d-has_geo-flickr-metadata.csv',
                  yyyy: ARGV[0].to_i, mm: ARGV[1].to_i, dd: ARGV[2].to_i)
CSV.open(FILENAME, 'w', write_headers: true, headers: headers) do |csv_object|
  csv_array.each { |row_array| csv_object << row_array }
end
