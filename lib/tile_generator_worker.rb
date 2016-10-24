require 'sidekiq'
require 'pry'

class TileGeneratorWorker
  include Sidekiq::Worker

  def perform(sources, offer)
    puts sources.inspect
    puts offer
  end
end
