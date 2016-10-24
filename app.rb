require 'sinatra'
require 'sidekiq'
require_relative 'lib/tile_generator_worker'

get "/" do
  "Welcome to Tile Generator"
end

post "/" do
  content_type :json
  req = JSON.load(request.body.read.to_s)

  TileGeneratorWorker.perform_async(req['sources'], req['offer'])

  status(202)
end
