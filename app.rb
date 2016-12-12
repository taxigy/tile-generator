require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader'
require 'sidekiq'
require 'dry-validation'
require 'uri'
require_relative 'lib/tile_generator_worker'
require_relative 'lib/s3_bucket'

def tokens
  ENV.keys.grep(/^SECRET_TOKEN_/).map { |k| ENV[k] }
end

def valid_token?(token)
  return false if token.nil?
  tokens.include?(token)
end

TileRequestSchema = Dry::Validation.Schema do
  required('offer').filled
  required('sources').filled(:array?) { each(:str?, format?: URI.regexp ) }
  optional('callback').maybe(:str?, format?: URI.regexp)
end

before do
  halt 403 unless valid_token?(request.env["HTTP_X_SECRET_TOKEN"])
end

get "/" do
  json result: "ok"
end

post "/" do
  content_type :json
  req = JSON.load(request.body.read.to_s)

  validation = TileRequestSchema.call(req)
  if validation.success?
    #TileGeneratorWorker.perform_async(req['sources'], req['offer'], 'callback'.freeze => req['callback'])

    status(202)
  else
    status 400
    json errors: validation.messages
  end
end
