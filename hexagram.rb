#!/Users/peterk/.rvm/rubies/ruby-1.9.3-p0/bin/ruby
load File.dirname(__FILE__) + "/lib.rb"
@start = Time.now

#ARGS: in_file, cols, colors

#things to play with...

#how much of each cell should the shape take up?
AMOUNT_OF_BOX = [1,0.5,0.9,1.2].sample
PACKING_STYLE = ["honeycomb","honeycomb","honeycomb","grid"] #usually honeycomb :)
SHAPES = ["circle","hexagon","hexagon"] #usually hexagon
COLUMNS = [2,3,5,8,12,20,30,40,60]

#how often do they get BIG
MUTATION_FREQUENCY = [0.2,0.5,0.15,0.15,0.15,0.1,0.05,0.01].sample #mostly 0.15
ENHANCE_CONTRAST = false
COLORS_PER_IMAGE = [5,10,50,500,1000,5000,10000].sample #for initial whole-image quantization
CROP_SQUARE = [true,true,false].sample #usually square :)

@target_width = 1500
@background = "fff" #ffe

#initialize these later
@box_height = @box_width = 0

OUT_DIR = "out"

require 'rmagick'
include Magick
require 'trollop'


#get a hash (2-dimensional array) indexed by [column][row]
#each item contains a hash of popular colors (keys are hex_codes & values are amounts for that color)

  #to support polygon opacity
  @myrsvgconvert = `which rsvg-convert`.chomp

  #if you don't care about polygon opacity...
  #@myconvert = `which convert`.chomp


#class ColorMapper
#  attr_accessor :scaled_img, :columns, :colors_per_cell, :packing

def get_scaled_img(img_file,cols=10,colors_per_cell=3,style="grid")
  #load 'er up, auto-orient, resize
  img = Magick::Image.read(img_file).first.auto_orient

  #"CenterGravity" is leaving a white border on top... so let's calculate manually
  min_dimension = img.columns
  min_dimension = img.rows if img.rows < img.columns
  #img.crop!(Magick::CenterGravity, min_dimension, min_dimension,true) if CROP_SQUARE
  img.resize_to_fill!(min_dimension,min_dimension) if @crop

  #quantize and resize for greater efficiency
  #use target columns & colors per square to determine reduced target size

  #.sigmoidal_contrast_channel(4).
  #or quantize the whole image...
  #.quantize(colors_per_cell*4)
  #cycle!
  #cycle_colormap(150)
  #normalize! make them blacks black and whites white...
  #quantize first to X colors
  @scaled_img = img.resize(cols.to_f * colors_per_cell / img.columns).quantize(@colors_per_image).normalize#.sigmoidal_contrast_channel(8)#.quantize(100)#sigmoidal_contrast_channel(2)
  @scaled_img = @scaled_img.sigmoidal_contrast_channel(4) if(ENHANCE_CONTRAST)
end

def get_rows_from_img(img,cols,style)
  rows = (img.rows / img.columns.to_f * cols).to_f
  #need extra rows if we're honeycomb packed
  rows /= Math.sin(Math::PI/3) if style != "grid"
  rows.ceil
end

def get_color_map(img_file,cols=10,colors_per_cell=3,style="grid")
  rows = get_rows_from_img(@scaled_img,cols,style)
  #scaled_img = img
  #square for now...
  #total num of pixels in new image
  #total = scaled_img.columns * scaled_img.rows

  # a shiny new histogram with RGB hex_colors & percentages
  blocks = Hash.new{|h, k| h[k] = []}

  cols.times do |c|
    rows.times do |r|
      blocks[c][r] = get_hash(c,r,@box_width,@box_height,colors_per_cell,style)
    end
  end
    blocks
end

# get a hash of colors for a single row * column of the image
# note that we adjust for packing style (grid vs honeycomb)
def get_hash(col,row,box_width,box_height,colors_per_cell,style)

      good_histogram = {}
      x = col*box_width
      x += box_width/2 if(row % 2 == 1 && style != "grid")
      y = row*box_height
      y = row*box_height * Math.sin(Math::PI/3).to_f if style != "grid"
      @scaled_img.crop(x,y,box_width,box_height).quantize(colors_per_cell).color_histogram().to_a.each do |color,count|
        #take each color component from the color object,
        #scale to max of 255 using QuantumRange property
        #pad with a space
        #convert space to 0 (hackety hack :(
        #glue it all together into one 6-char hex color string
        hex_code = ""
        [color.red,color.green,color.blue].each  {|color| hex_code += ("% 2s" % (color * 255 / QuantumRange).to_s(16)).gsub(" ",'0') }
        #number of pixels of that color divided by total num of pixels (round to 2 decimals)
        pixels_in_box = box_height * box_width
        percentage = (count / pixels_in_box.to_f).round(2)
        good_histogram[hex_code] = percentage
      end
      good_histogram#.sort{|a,b| a <=> b}
end

# get the color map
# randomly choose a row & column
# rebuild the image as vectors
def go(file,cols=10,colors=5, packing="grid", shape="hexagon")
  #color_map = get_color_map(file,cols,colors,packing)
  #rows = color_map[0].size #HACK! Just counting the elements in the first columns

  rows = get_rows_from_img(@scaled_img,cols,packing)

  box_width = box_height = @target_width / cols
  #margins are good. Let's always use 'em
  margin = box_width * 3

  amount_of_box = @amount_of_box  #use a non-1 value for more or less of the box

  @width = (cols * box_width)
  @height = (rows * box_height)

  if packing != "grid"
    amount_of_box *= 1/Math.sin(Math::PI/3)
    @width -= box_width/2
    @height *= Math.sin(Math::PI/3)
    @height -= box_height * Math.sin(Math::PI/3)
  end

  max_rad = amount_of_box * box_width/2
  @width += margin*2
  @height += margin*2


 # debug "Colors in #{in_file}: #{colors.count}"
  #max_width = max_height = max_rad  * 2
  #make a circle for each color in the hash (which should already be orderd by largest to smallest)

  #for status reporting
  total = rows * cols
  current = 0
  old_percentage = -1

  #shuffle things up so they don't get rendered sequentially and look like theatre seats
  [*(0..rows-1)].shuffle.each do |r|
  #rows.times do |r|
    [*(0..cols-1)].shuffle.each do |c|
    #cols.times do |c|
      #color_hash = color_map[c][r]
      color_hash = get_hash(c,r,@box_width,@box_height,colors,packing)

      current_scale = 1
      last_scale = 0

      #starting point...
      x = c*box_width
      y = r*box_height

      if(packing != "grid")
        #honeycomb!
        x += box_width * Math.cos(Math::PI/3) if(r % 2 ==1)
        y *= Math.sin(Math::PI/3)
      else
        x += box_height/2
        y += box_width/2
      end

      x += margin
      y += margin

      temp_max_rad = max_rad
      #explodio!
      if rand > 1-@mutation_frequency
        temp_max_rad = max_rad * [1,1.5,2,2.5,3].sample #(1+rand*2)
      end

      #wiggle!!!
      #wiggle_amount = box_width * 0
      #x += -wiggle_amount + wiggle_amount*rand
      #y += -wiggle_amount + wiggle_amount*rand


      #update our status file
      percentage = (100*current/total).to_i
      current += 1

      if(@status_file && percentage % 5 == 0 && percentage != old_percentage)
        #puts percentage
         old_percentage = percentage
         update_status(percentage)
      end

      color_hash.keys.sort{|a,b| color_hash[b] <=> color_hash[a]}.each do |hex_code|
        scale = color_hash[hex_code]
        #puts "#{hex_code} : #{scale}"
        #gets
        #determine the size
        #measure the radius by subtracting how big the previous radius was
        rad = temp_max_rad * (current_scale - last_scale)
        current_scale -= last_scale

        type = (c % 2 == 0) ? "up" : "down"
        #eq_triangle x,y,rad,hex_code, type

        opacity = [*(85..100),*(95..100)].sample / 100.0
        #opacity = 100

        case shape
        when "hexagon"
          hexagon x,y, rad, hex_code, 0,0,opacity
        when "square"
          rect x-rad,y-rad, rad*2, rad*2, hex_code, 0,0,opacity
        when "triangle"
          rotation = 0 #((r+c) % 2) * 180
          #puts rotation
          x = margin + (c * (rad * Math.sin(Math::PI/3)))
          y = margin + (r * (rad * Math.cos(Math::PI/3)*2))
          #y = margin + (r * box_width) + (rad*Math.cos(Math::PI*2*rotation/360))
          #y -= (rad*Math.cos(Math::PI)) if rotation == 180

          #for triangles
          #cx = x - Math.sin(Math::PI/3) - box_width/2
          #cy = y - (rad*Math.cos(Math::PI*2*rotation/360))

          ngon 3, x, y, rad, hex_code, 0, 0, opacity, rotation
        #when "heart"

        else
          circle x,y, rad, hex_code,0,0,opacity
        end

        last_scale = scale
      end
    end
  end
end

def show_elapsed_time
  #uncomment for benchmarking
  #puts "#{Time.now - @start} seconds"
end

def update_status(amount)
  if(@status_file)
    IO.write(@status_file,amount)
  end
end



require 'trollop'
 opts = Trollop::options do
   opt :packing, "Packing style: honeycomb or grid", :type=> :string
   opt :shape, "Hexagon, circle, or triangle" , :type=> :string
   opt :columns, "Columns - leave blank for random", :type=>:integer                # flag --monkey, default false
   #opt :margin, "Margin (pixels)", :type=>:integer
   opt :colors_per_cell, "Colors per cell", :default => 4, :type => :integer        # string --name <s>, default nil
   opt :colors_per_image, "Total colors in the image", :type=>:integer
   opt :out_file, "File to write", :type=> :string  # integer --num-limbs <i>, default to 4
   opt :mutation_frequency, "What percent of the time should we mutate?", :type=>:float
   opt :status_file, "file to save build progress", :type=> :string  # integer --num-limbs <i>,
   opt :crop, "Crop to square?", :type=> :boolean, :default=>false
   opt :amount_of_box, "Amount of box (1 == 100%)", :type=> :float
   #default to 4
 end

in_file = ARGV[0] or abort ("No input file specified :(")
@out_file = opts[:out_file].to_s
columns = opts[:columns] || COLUMNS.sample
packing = opts[:packing] || PACKING_STYLE.sample
colors_per_cell = opts[:colors_per_cell] || [1,2,3,5].sample
shape = opts[:shape] || SHAPES.sample
@colors_per_image = opts[:colors_per_image] || COLORS_PER_IMAGE
@amount_of_box = opts[:amount_of_box] || AMOUNT_OF_BOX
@mutation_frequency = opts[:mutation_frequency] || MUTATION_FREQUENCY

#@margin = opts[:margin] || @margin
@status_file = opts[:status_file]
if(opts[:crop].to_s.empty?)
  @crop = CROP_SQUARE
else
  @crop = opts[:crop]
end

#raise shape
#exit

update_status 0

show_elapsed_time

get_scaled_img in_file,columns,colors_per_cell,packing
show_elapsed_time
@box_width = @box_height = @scaled_img.columns / columns
go in_file, columns, colors_per_cell, packing, shape

#remove status file
File.unlink @status_file unless @status_file.nil?

if(!@out_file.empty?)
  save_file @out_file
else
  puts build
end

show_elapsed_time
#system("nice -n 8 #{@myrsvgconvert} #{OUT_DIR}/#{name} -o #{OUT_DIR}/#{name.sub('.svg','.png')}")
