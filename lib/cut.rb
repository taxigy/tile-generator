require 'open-uri'
require 'mini_magick'
require_relative "s3_bucket"

def root_dir
  root = File.expand_path(File.join(File.dirname(__FILE__), '..', 'temp'))
  Dir.mkdir(root) unless File.exists?(root)
  root
end

def dimensions
  base_zoom = ENV.fetch('BASE_ZOOM', '16').to_i
  base_density = ENV.fetch('BASE_DENSITY', '300').to_i
  zoom_levels = ENV.fetch('ZOOM_LEVELS', '0, -1, -2')

  zoom_levels.split(/,\s+/).map do |z|
    z = z.to_i
    density = (base_density * 2 ** z).to_i
    scale = "#{(base_density * 2 ** z / base_density * 100).to_i}%"

    [density, scale, base_zoom + z]
  end
end

def download_images(source_urls, offer)
  source_urls.map.with_index do |url, index|
    filename = File.join(root_dir, "#{offer}_#{index}.png")

    open(filename, "wb") do |file|
      file << open(url).read
    end

    filename
  end
end

def prepare(offer, density, scale, zoom, source_images)
  out = File.join(root_dir, "offer_#{zoom}.png")

  MiniMagick::Tool::Convert.new do |convert|
    convert << "-density" << density
    convert << "-background" << 'white'
    convert << "-alpha" << "remove"
    source_images.each do |src|
      convert << src
    end
    convert << "+append"
    convert << "-resize" << scale
    convert << out
  end

  out
end

def resolution(png)
  out = MiniMagick::Tool::Identify.new do |identify|
    identify << png
  end
  matching = /PNG\s(\d+)x(\d+)/.match(out)
  [matching[1].to_i, matching[2].to_i]
end

def make_tiles!(offer, zoom, png)
  original_width, original_height = resolution(png)
  rounded_width = original_width + 256 - (original_width % 256)
  rounded_height = original_height + 256 - (original_height % 256)

  normalized_png = File.join(root_dir, "#{offer}_normalized_#{zoom}.png")
  # `convert -gravity center -background white -extent "#{rounded_width}x#{rounded_height}" "#{intermediary_png}" "#{intermediary_png}"`
  MiniMagick::Tool::Convert.new do |convert|
    convert << "-gravity" << "center"
    convert << "-background" << "white"
    convert << "-extent" << "#{rounded_width}x#{rounded_height}"
    convert << png
    convert << normalized_png
  end

  # `convert -crop "256x256" +repage +adjoin "#{intermediary_png}" "tile_#{offer}_#{zoom}_%01d.jpg"`
  tile_name = File.join(root_dir, "tile_#{offer}_#{zoom}_%01d.jpg")
  MiniMagick::Tool::Convert.new do |convert|
    convert << "-crop" << "256x256"
    convert << "+repage"
    convert << "+adjoin"
    convert << normalized_png
    convert << tile_name
  end

  File.delete(normalized_png)

  cols = (rounded_width / 256).to_i
  rows = (rounded_height / 256).to_i
  images_count = cols * rows

  col = 0
  row = 0
  tiles = (0...images_count).map do |n|
    initial = File.join(root_dir, "tile_#{offer}_#{zoom}_#{n}.jpg")
    target = File.join(root_dir, "tile_#{offer}_#{zoom}_#{col}_#{row}.jpg")
    File.rename(initial, target)

    col += 1
    if col >= cols
      col = 0
      row += 1
    end

    target
  end

  tiles
end

def cut(source_urls, offer)
  s3_delete_dir(offer)

  dimensions.each do |density, scale, zoom|
    source_images = download_images(source_urls, offer)
    intermediary_png = prepare(offer, density, scale, zoom, source_images)
    tiles = make_tiles!(offer, zoom, intermediary_png)

    tiles.each do |tile|
      dest = "#{offer}/#{File.basename(tile)}"
      s3_upload(tile, dest)
    end

    File.delete(*source_images)
    File.delete(intermediary_png)
    File.delete(*tiles)
  end
end

# cut [ARGV[0], ARGV[1], ARGV[2]], "abcxyz"
# NOTE: to test, uncomment previous line and run in shell:
# ruby cut.rb "https://placeholdit.imgix.net/~text?txtsize=19&txt=200%C3%97200&w=200&h=200" "https://placeholdit.imgix.net/~text?txtsize=19&txt=200%C3%97200&w=200&h=200" "https://placeholdit.imgix.net/~text?txtsize=19&txt=200%C3%97200&w=200&h=200"
