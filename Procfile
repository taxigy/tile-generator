web: bundle exec rackup config.ru -p $PORT
worker: bundle exec sidekiq -r ./lib/tile_generator_worker.rb -C ./config/sidekiq.yml
