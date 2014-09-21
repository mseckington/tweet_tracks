require 'json'
require 'rspotify'

class HomepageController < ApplicationController

  def index
    @tweets = Tweet.all.order('created_at DESC').limit(10)
  end

  def reload_tweets
    client = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end

    tweets = client.home_timeline(count: 40)

    conn = Faraday.new(:url => 'https://api.dandelion.eu') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    @results = []

    tweets.each do |tweet|
      response = conn.get "/datatxt/nex/v1/?min_confidence=0.5&lang=en &social.parse_hashtag=True&text=#{tweet.text}&include=image&$app_id=#{ENV['DANDELION_APP_ID']}&$app_key=#{ENV['DANDELION_APP_KEY']}"
      converted_response = JSON.parse(response.body)

      next if converted_response["annotations"].blank?

      # image_urls = converted_response["annotations"].inject([]){|images, x| x["image"]["thumbnail"] ? images << x["image"]["thumbnail"] : images}
      # puts image_urls

      entities = converted_response["annotations"]

      track = "emptyempty"
      label = ""

      entities.each do |entity|
        label = entity["label"]
        tracks = RSpotify::Track.search(label)
        puts tracks.count

        if tracks.count > 0
          track = tracks.first
          break
        end
      end

      puts track
      puts label
      next if track == "emptyempty"

      puts "herehere"
      puts label

      Tweet.create(
        text: tweet.text,
        # image_urls: image_urls.take(6),
        label: label,
        track_name: track.name,
        track_image: track.album.images[1]["url"].to_s,
        track_url: track.external_urls["spotify"],
        track_artist: track.artists.map{|a| a.name}.join(" & "),
        spotify_id: track.id,
        user_name: tweet.user.screen_name,
        user_image: tweet.user.profile_image_url.to_s
      )
    end

    redirect_to root_path
  end
end



