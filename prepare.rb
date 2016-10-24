source_images = ARGV[0] # TODO: get from HTTP POST request
offer = ARGV[1] # TODO: get from HTTP POST request
base_zoom = ENV["BASE_ZOOM"] or 16 # for example, 16
base_density = ENV["BASE_DENSITY"] or 300 # base PDF density
zoom_levels = ENV["ZOOM_LEVELS"] or "0, -1, -2"

dimensions = zoom_levels.split(/,\s+/).map do |z|
  z = z.to_i
  density = (base_density * 2 ** z).to_i
  scale = "#{(base_density * 2 ** z / base_density * 100).to_i}%"
  [density, scale, base_zoom + z]
end

dimensions.each do |density, scale, zoom|
  intermediary_png = "source_#{zoom}.png"
  `convert -density #{density} -background white -alpha remove #{source_images.join(" ")} +append -resize #{scale} #{intermediary_png}`
  matching = /(\d+)x(\d+)$/.match `identify #{intermediary_png}`
  original_width = matching[1].to_i
  original_height = matching[2].to_i
  rounded_width = width + 256 - (width % 256)
  rounded_height = height + 256 - (height % 256)
  cols = (width2 / 256).to_i
  rows = (height2 / 256).to_i
  puts "Initial dimensions: #{original_width}x#{original_height}, new dimensions: #{rounded_width}x#{rounded_height}"
  `convert -gravity center -background white -extent "#{rounded_width}x#{rounded_height}" "#{intermediary_png}" "#{intermediary_png}"`
  `convert -crop "256x256" +repage +adjoin "#{intermediary_png}" "tile_#{offer}_#{zoom}_%01d.jpg"`

  col = 0
  row = 0
  (0...(cols * rows)).each do |n|
    initial = "tile_#{offer}_#{zoom}_#{n}.jpg"
    target = "tile_#{offer}_#{zoom}_#{col}_#{row}.jpg"

    puts "#{initial} -> #{target}"

    `mv #{initial} #{target}`

    col += 1

    if col >= cols
      col = 0
      row += 1

      # TODO: upload and `rm #{target}`
    end
  end
end
