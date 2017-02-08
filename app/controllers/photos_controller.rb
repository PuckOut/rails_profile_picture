require 'capybara'
require 'capybara/dsl'
require 'capybara/rails'
class PhotosController < ApplicationController
  include Capybara::DSL
  def get_facebook_avatar

    oauth = Koala::Facebook::OAuth.new('app_id','app_secret')
    oauth_access_token = oauth.get_app_access_token
    graph = Koala::Facebook::API.new(oauth_access_token)
    # can get through https://graph.facebook.com/oprahwinfrey/picture?type=large
    begin

      pageProfilePhoto = graph.get_picture_data(params[:username], type: :large)
      image = open(pageProfilePhoto['data']['url'])
      IO.copy_stream(image, "/tmp/#{params[:username]}.jpg")
      file = open("/tmp/#{params[:username]}.jpg")
      send_file( file,
          :disposition => 'inline',
          :type => 'image/jpeg',
          :x_sendfile => true )

    rescue Koala::Facebook::ClientError => error
      # facebook block any info from user outside of your app, login into a account and get it ¯\_(ツ)_/¯
      Capybara.run_server = false
      Capybara.current_driver = :webkit
      Capybara.javascript_driver = :webkit

      visit('http://www.facebok.com')
      within 'form#login_form' do
        find('input[name="email"]').set "email@email.com"
        find('input[name="pass"]').set "password"
        find('input[type="submit"]').click
      end
      visit("http://www.facebok.com/#{params[:username]}")
      # sleep 5 # my internet suck
      resultado = Nokogiri::HTML(body)
      # force reset for kill sessions/cookies
      page.reset!

      pageUserPhoto = resultado.css('img.profilePic')
      image = open(pageUserPhoto.attr('src'))
      IO.copy_stream(image, "/tmp/#{params[:username]}.jpg")
      file = open("/tmp/#{params[:username]}.jpg")
      send_file( file,
          :disposition => 'inline',
          :type => 'image/jpeg',
          :x_sendfile => true )
    end
  end
  def get_instagram_avatar
    access_token = "access_token"
    Instagram.configure do |config|
      config.client_id = "client_id"
      config.client_secret = "client_secret"
    end

    client = Instagram.client(:access_token => access_token)
    user = client.user_search("#{params[:username]}")
    # get the first user
    image = open(user[0].profile_picture)
    IO.copy_stream(image, "/tmp/#{params[:username]}.jpg")
    file = open("/tmp/#{params[:username]}.jpg")
    send_file( file,
        :disposition => 'inline',
        :type => 'image/jpeg',
        :x_sendfile => true )

  end
  def get_twitter_avatar
    # easy one
    image = open("https://twitter.com/#{params[:username]}/profile_image?size=original")
    send_file( image,
        :disposition => 'inline',
        :type => 'image/jpeg',
        :x_sendfile => true )
  end
  def get_youtube_avatar
    # care use /channel/id users, need to do a rescue for this error and change the url
    Yt.configuration.api_key = "api_key"
    channel = Yt::Channel.new url: "https://www.youtube.com/user/#{params[:username]}/"
    image = open(channel.thumbnail_url)
    IO.copy_stream(image, "/tmp/#{params[:username]}.jpg")
    file = open("/tmp/#{params[:username]}.jpg")
    send_file( file,
        :disposition => 'inline',
        :type => 'image/jpeg',
        :x_sendfile => true )
  end
end
