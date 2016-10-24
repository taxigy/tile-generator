# replace ARGV with HTTP POST requires params
source_images = ARGV[0]
base_zoom = ARGV[1] or 16 # for example, 16
source_format = ARGV[2] or "pdf" # "pdf", otherwise "jpg"
base_density = ARGV[3] or 300 # base PDF density
zoom_levels = ARGV[4] or [0, -1, -2]

dimensions = zoom_levels.map do |z|
  density = (base_density * 2 ** z).to_i
  scale = "#{(base_density * 2 ** z / base_density * 100).to_i}%"
  [density, scale, z]
end

dimensions.each do |density, scale, zoom|
  intermediary_png = "source_#{zoom}.png"
  if source_format == "pdf"
    `convert #{source_images.join(" ")} +append -resize #{scale} #{intermediary_png}`
  else
    `convert -density #{density} -background white -alpha remove "#{source_images}" +append "#{intermediary_png}"`

  matching = /(\d+)x(\d+)$/.match `identify #{png}`
  original_width = matching[1].to_i
  original_height = matching[2].to_i
  rounded_width = width + 256 - (width % 256)
  rounded_height = height + 256 - (height % 256)
  cols = (width2 / 256).to_i
  rows = (height2 / 256).to_i
  puts "Initial dimensions: #{original_width}x#{original_height}, new dimensions: #{rounded_width}x#{rounded_height}"
  `convert -gravity center -background white -extent "#{rounded_width}x#{rounded_height}" "#{intermediary_png}" "#{intermediary_png}"`
  `convert -crop "256x256" +repage +adjoin "#{intermediary_png}" "tile_#{zoom}_%01d.jpg"`

  col = 0
  row = 0
  (0...(cols * rows)).each do |n|
    initial = "tile_#{zoom}_#{n}.jpg"
    target = "tile_#{zoom}_#{col}_#{row}.jpg"

    puts "#{initial} -> #{target}"

    `mv #{initial} #{target}`

    col += 1

    if col >= cols
      col = 0
      row += 1
    end
  end
end
