require 'open-uri'

def cut source_urls, offer
  ENV["BASE_ZOOM"] ||= "16"
  ENV["BASE_DENSITY"] ||= "300"
  ENV["ZOOM_LEVELS"] ||= "0, -1, -2"
  base_zoom = ENV["BASE_ZOOM"].to_i
  base_density = ENV["BASE_DENSITY"].to_i
  zoom_levels = ENV["ZOOM_LEVELS"]
  dimensions = []

  zoom_levels.split(/,\s+/).each do |z|
    z = z.to_i
    density = (base_density * 2 ** z).to_i
    scale = "#{(base_density * 2 ** z / base_density * 100).to_i}%"
    dimensions.push [density, scale, base_zoom + z]
  end

  dimensions.each do |density, scale, zoom|
    images_count = 0
    source_images = []
    source_urls.each do |url|
      filename = "#{offer}_#{images_count}.png"

      open(filename, "wb") do |file|
        file << open(url).read
      end

      images_count += 1
      source_images.push filename
    end

    intermediary_png = "source_#{zoom}.png"
    `convert -density #{density} -background white -alpha remove #{source_images.join(" ")} +append -resize #{scale} "#{intermediary_png}"`
    matching = /PNG\s(\d+)x(\d+)/.match `identify #{intermediary_png}`
    original_width = matching[1].to_i
    original_height = matching[2].to_i
    rounded_width = original_width + 256 - (original_width % 256)
    rounded_height = original_height + 256 - (original_height % 256)
    cols = (rounded_width / 256).to_i
    rows = (rounded_height / 256).to_i
    puts "Initial dimensions: #{original_width}x#{original_height}, new dimensions: #{rounded_width}x#{rounded_height}"
    `convert -gravity center -background white -extent "#{rounded_width}x#{rounded_height}" "#{intermediary_png}" "#{intermediary_png}"`
    `convert -crop "256x256" +repage +adjoin "#{intermediary_png}" "tile_#{offer}_#{zoom}_%01d.jpg"`

    col = 0
    row = 0
    (0...(cols * rows)).each do |n|
      initial = "tile_#{offer}_#{zoom}_#{n}.jpg"
      target = "#{offer}/tile_#{offer}_#{zoom}_#{col}_#{row}.jpg" # NOTE: putting result tiles into a folder

      puts "#{initial} -> #{target}"
      `mv "#{initial}" "#{target}"`

      col += 1

      if col >= cols
        col = 0
        row += 1

        # TODO: upload
        # `rm #{initial} #{target}`
      end
    end

    `rm "#{intermediary_png}"`

    (0...images_count).each do |n|
      `rm "tile_#{offer}_#{zoom}_#{n}.jpg"`
    end
  end
end

# cut [ARGV[0], ARGV[1], ARGV[2]], "abcxyz"
# NOTE: to test, uncomment previous line and run in shell:
# ruby cut.rb "https://placeholdit.imgix.net/~text?txtsize=19&txt=200%C3%97200&w=200&h=200" "https://placeholdit.imgix.net/~text?txtsize=19&txt=200%C3%97200&w=200&h=200" "https://placeholdit.imgix.net/~text?txtsize=19&txt=200%C3%97200&w=200&h=200"
