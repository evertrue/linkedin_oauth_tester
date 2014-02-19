require 'sinatra/base'
require 'active_support/all'

class CallbackService < Sinatra::Application
  get '/oauth/callback' do
    code, state = params[:code], params[:state]

    content_type :json
    { code: code, state: state }.to_json
  end
end
