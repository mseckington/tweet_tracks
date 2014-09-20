require 'json'

class HomepageController < ApplicationController

  def index

    client = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end

    tweets = client.home_timeline(count: 10)

    conn = Faraday.new(:url => 'https://api.dandelion.eu') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    @results = []

    tweets.each do |tweet|
      response = conn.get "/datatxt/nex/v1/?min_confidence=0.1&lang=en &text=#{tweet.text}&include=image&$app_id=cb93dde4&$app_key=5366ca18b641266f05c0447a0ee8b1a8"
      converted_response = JSON.parse(response.body)
      if converted_response["annotations"].blank?
        next
      end
      puts converted_response["annotations"].count
      puts converted_response["annotations"]
      image_urls = converted_response["annotations"].inject([]){|images, x| x["image"]["thumbnail"] ? images << x["image"]["thumbnail"] : images}
      puts image_urls
      @results << {
        :text => tweet.text,
        :image_urls => image_urls.take(6),
        :name => tweet.user.screen_name,
        :profile_image => tweet.user.profile_image_url
      }
    end

    @results
  end
end



