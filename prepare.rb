pdf = ARGV[0]
ms = [[300, 16], [150, 15]]

ms.each do |density, zoom|
  png = "source_#{zoom}.png"
  `convert -density #{density} -background white -alpha remove "#{pdf}" +append "#{png}"`
  matching = /^.*PNG\s(\d+)x(\d+).*$/.match `identify #{png}`
  width = matching[1].to_i
  height = matching[2].to_i
  width2 = width + 256 - (width % 256)
  height2 = height + 256 - (height % 256)
  cols = width2 / 256
  rows = height2 / 256
  puts "Initial dimensions: #{width}x#{height}, new dimensions: #{width2}x#{height2}"
  `convert -gravity center -background white -extent "#{width2}x#{height2}" "#{png}" "#{png}"`
  `convert -crop "256x256" +repage +adjoin "#{png}" "tile_#{zoom}_%01d.png"`

  col = 0
  row = 0
  (0...(cols * rows)).each do |n|
    initial = "tile_#{zoom}_#{n}.png"
    target = "tile_#{zoom}_#{col}_#{row}.png"

    puts "#{initial} -> #{target}"

    `mv #{initial} #{target}`

    col += 1

    if col >= cols
      col = 0
      row += 1
    end
  end
end
