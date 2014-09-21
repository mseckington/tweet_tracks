class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.string :text
      t.string :label
      t.string :track_name
      t.string :track_image
      t.string :track_url
      t.string :track_artist
      t.string :spotify_id
      t.string :user_name
      t.string :user_image

      t.timestamps
    end
  end
end
