require 'sidekiq'
require_relative './upload'

class TileGeneratorWorker
  include Sidekiq::Worker

  def perform(sources, offer)
    file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'temp', 'test.html'))
    upload(file)
  end
end
