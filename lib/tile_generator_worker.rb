require 'sidekiq'
require_relative './cut'

class TileGeneratorWorker
  include Sidekiq::Worker

  def perform(sources, offer)
    cut(sources, offer)
  end
end
