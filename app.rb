#!/usr/bin/env ruby

require 'bundler'

require 'dotenv'
Dotenv.load

require 'sinatra/base'
require 'active_support/all'

require 'securerandom'
require 'linkedin2'
require 'selenium-webdriver'
require 'yaml'
require 'redis'
require 'open-uri'
require 'cgi'
require 'byebug'

def linkedin_client
  @linkedin_client ||= LinkedIn::Client.new key: ENV['LINKEDIN_APP_KEY'],
                                            secret: ENV['LINKEDIN_SECRET'],
                                            redirect_uri: 'http://localhost:9292/oauth/callback',
                                            scope: %i(r_basicprofile w_messages r_emailaddress r_network)
end

def webdriver
  @webdriver ||= Selenium::WebDriver.for :chrome
end

class LinkedinOauthTest < Sinatra::Application
  get '/oauth/callback' do
    code, state = params[:code], params[:state]

    content_type :json
    { code: code, state: state }.to_json
  end
end

if __FILE__==$0
  puts "Running..."

  accounts = YAML.load_file('accounts.yml')

  redis = Redis.new

  accounts.each do |name, config|
    puts name

    if last_run = redis.get("lidstest:accounts:#{name}:last_run")
      puts "\t- Last run at #{DateTime.parse last_run}, skipping."
      next
    end

    expire = config['delay'].to_i.minutes.to_i
    redis.set "lidstest:accounts:#{name}:last_run", DateTime.now.to_s, ex: expire

    state = SecureRandom.hex
    oauth_url = linkedin_client.authorize_url state: state

    webdriver.get oauth_url

    element = webdriver.find_element id: 'session_key-oauth2SAuthorizeForm'
    element.send_keys config['username']

    element = webdriver.find_element id: 'session_password-oauth2SAuthorizeForm'
    element.send_keys config['password']

    element.submit

    params = CGI::parse(URI.parse(webdriver.current_url).query)

    code, state = params['code'].first, params['state'].first

    redis.incr "lidstest:attemps"

    cache = { success: true, code: code, state: state }

    begin
      token = linkedin_client.request_access_token(code).token
      cache.merge! token: token if token

      profile = linkedin_client.profile '~'
      cache.merge! uid: profile.id if profile

      redis.sadd "lidstest:successes", "accounts:#{name}:#{state}"
      puts "\tToken generated: #{token}"
    rescue => e
      cache.merge! error_message: e.message, error_type: e.class.to_s

      redis.sadd "lidstest:failures", "accounts:#{name}:#{state}"
      puts "\tFailed to generate valid token"
    ensure
      redis.hmset "lidstest:accounts:#{name}:#{state}", *cache.to_a.flatten
    end
  end

  webdriver.quit
end
