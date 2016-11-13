require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader'
require 'sidekiq'
require 'dry-validation'
require 'uri'
require_relative 'lib/tile_generator_worker'
require_relative 'lib/s3_bucket'

TileRequestSchema = Dry::Validation.Schema do
  required('offer').filled
  required('sources').filled(:array?) { each(:str?, format?: URI.regexp ) }
  optional('callback').maybe(:str?, format?: URI.regexp)
end

get "/" do
  json result: "ok"
end

post "/" do
  content_type :json
  req = JSON.load(request.body.read.to_s)

  validation = TileRequestSchema.call(req)
  if validation.success?
    TileGeneratorWorker.perform_async(req['sources'], req['offer'], 'callback'.freeze => req['callback'])

    status(202)
  else
    status 400
    json errors: validation.messages
  end
end
