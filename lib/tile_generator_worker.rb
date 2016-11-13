require 'net/http'
require 'sidekiq'
require_relative './cut'

class TileGeneratorWorker
  include Sidekiq::Worker

  def perform(sources, offer, options={})
    cut(sources, offer)

    if options['callback'.freeze]
      uri = URI(options['callback'])
      p "MAKE REQUEST"
      Net::HTTP.get(uri)
    else
      p "SOMETHINKG WENT WRONG", options['callback'.freeze]
    end

  rescue RuntimeError => e
    p "ERROR", e.inspect
  end
end
