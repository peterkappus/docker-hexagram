#version 1.3

# revision history
# 1.0 added stroke opacity
# 1.1 Added Polygon & draw_border methods
# 1.2 - IN PROGRESS: add method to extract colors - CANCELLED...
# 1.3 - Added Hexagon method
# 1.4 - created generic "ngon" method and refactored hexagon method to use this

#include this file (include './lib.rb') and use the functions below...
#add SVG to the @yield variable then call "output" when you're done


#NOTE: set the @height & @width as desired

  @height = 1500
  @width = @height * 2 #@height * 1.618 # golden ratio, yo!
  @margin = @width/10
  @priority = 6
  @background = "222"

  @yield = ""
  @myconvert = `which convert`.chomp
  @myrsvgconvert = `which rsvg-convert`.chomp
  @keywords = "ocean ice sky glacier mosaic arabia temple church mosque inlay sand desert nature sand shadow arabic fire earth sea tree rock heat india spice wood sweet milk jungle green polyester egypt mountain stone river "

#shouldn't need this...
#as long as nice is found, we don't care which one we're using
#@mynice = `which nice`

#generate a random hex color value
def rand_color
  "%06x" % (rand * 0xffffff)
end

def get_rand_keyword
  @keywords.split(' ').sample
end

def curve(x,y,x2,y2,x3,y3,stroke_color=rand_color,thickness=3)
  @yield += %Q^<path d="M #{x} #{y} q #{x2} #{y2} #{x3} #{y3}" fill="none" stroke="##{stroke_color}" stroke-width="#{thickness}" />\n^
end


def triangle(x,y,rad,color=rand_color,stroke_width=0,stroke_color="000",fill_opacity=1)
  ngon(6,x,y,rad,color,stroke_width,stroke_color,fill_opacity)
end

def hexagon(x,y,rad,color=rand_color,stroke_width=0,stroke_color="000",fill_opacity=1)
  #rad *= ([*(80..120)].sample)/100.00
  ngon(6,x,y,rad,color,stroke_width,stroke_color,fill_opacity)
end

def ngon(num_of_points,x,y,rad,color=rand_color,stroke_width=0,stroke_color="000",fill_opacity=1,rotation=0)
  num_of_points = num_of_points
  points = []
  num_of_points.times do |i|
   points << (x + (rad * Math.sin(i*2*Math::PI/num_of_points))).round
   points << (y + (rad * Math.cos(i*2*Math::PI/num_of_points))).round
  end
  #points = [x,y-rad, x+rad/2,y-rad/2, x+rad,y, x+rad/2,y+rad/2, x,y+rad, x-rad/2,y+rad/2, x-rad,y, x-rad/2,y-rad/2]
  polygon(points,color,stroke_width,stroke_color,fill_opacity,"#{rotation} #{x} #{y}")
end

#NOTE: rotation string is the degree amount AND the x y pair
def polygon(points,color='000',stroke_width=0,stroke_color="000",fill_opacity=1,rotation_str='')
  point_str = ""
  points.each_slice(2).to_a.map{|point| point_str += "#{point[0]},#{point[1]} "}
  stroke = "stroke:##{stroke_color};stroke-width:#{stroke_width};" if stroke_width > 0
  fill_opacity_str = %Q^fill-opacity:#{fill_opacity};^ if (fill_opacity < 1)
  transform = "transform=\"rotate(#{rotation_str})\"" unless(rotation_str.empty? || rotation_str.to_i == 0)
  @yield += %Q^<polygon points="#{point_str}" #{transform} fill="##{color}" style="fill:##{color};#{stroke}#{fill_opacity_str}"/>\n^
end

#def wiggle(value,lower_range,upper_range)
#  value * [*(lower_range*100..uper_range*100)].sample/100.00
#end

def wiggle(value,wiggle_amount)
  rand(value*(1-wiggle_amount)..value*(1+wiggle_amount))
end

def eq_triangle(x,y,rad,color=rand_color,direction="up",stroke_width=0,stroke_color=0,fill_opacity=0)
  points = []
  flip_flop = (direction == "up") ? -1 : 1
  3.times do |i|
    points.push x + (rad * Math.sin(2*i*Math::PI/3))
    points.push y + (rad * flip_flop * Math.cos(2*i*Math::PI/3))
  end
  polygon points, color, stroke_width, stroke_color,fill_opacity
end

#make an SVG circle
def circle(x,y,radius,color=rand_color,stroke_width=0,stroke_color="000",fill_opacity=1)
  #break out the stroke because imagemagick doesn't correctly ignore a stroke with width of "0"
  #so it's best to leave out all mention of stroke unless we actually want one
  stroke = %Q^stroke-width="#{stroke_width}" stroke-opacity="#{fill_opacity}" stroke="##{stroke_color}"^ if(stroke_width > 0)
  fill_opacity_str = %Q^fill-opacity="#{fill_opacity}"^ if (fill_opacity < 1)
  @yield += %Q^<circle fill="##{color}" #{stroke} #{fill_opacity_str} cx="#{x}" cy="#{y}" r="#{radius}"/>\n^
end

def heart(x,y,radius,color=rand_color,stroke_width=0,stroke_color="000",fill_opacity=1)

end


#make a rectangle
def rect(x,y,w,h,color,stroke_width=0,stroke_color="000",opacity=1,stroke_opacity=1)
  #specify opacity AFTER stroke color... see: http://www.imagemagick.org/discourse-server/viewtopic.php?f=3&t=10594
  if(stroke_width > 0)
    stroke = %Q^stroke-width="#{stroke_width}"  stroke="##{stroke_color}" stroke-opacity="#{stroke_opacity}"^
  else
    stroke = %Q^ stroke="none" ^
  end
  opacity_str = " opacity=\"#{opacity}\" " if opacity < 1
  @yield += %Q^<rect x="#{x}" y="#{y}" fill="##{color}" #{opacity_str} #{stroke} width="#{w}" height="#{h}"/>\n^
end

def wiggly_rect(wiggle_amount,x,y,w,h,color,stroke_width=0,stroke_color="000",opacity=1,stroke_opacity=1)

  x1 = wiggle(x,wiggle_amount)
  y1 = wiggle(y,wiggle_amount)

  x2 = x + wiggle(w,wiggle_amount)
  y2 = wiggle(y,wiggle_amount)

  x3 = x + wiggle(w,wiggle_amount)
  y3 = y + wiggle(h,wiggle_amount)

  x4 = wiggle(x,wiggle_amount)
  y4 = y + wiggle(h,wiggle_amount)


  points = [x1,y1,x2,y2,x3,y3,x4,y4]

  polygon(points,color,stroke_width,stroke_color,opacity)
end


#wrap our @yield in an SVG doc
def build
  #originally had this in an ERB file but refactored so I can put everything in one file
    out = %Q^<?xml version="1.0"?>
      <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
      <svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
      	 width="#{@width}px" height="#{@height}px" viewBox="0 0 #{@width} #{@height}" enable-background="new 0 0  #{@width} #{@height}" xml:space="preserve">
      <desc>Awesomeness by Peter</desc>
      <rect x="0" y="0" fill="##{@background}" width="#{@width}" height="#{@height}"/>^

      out += %Q^#{@yield}</svg>^
end

#save the file (remember to include the SVG extension)
def save_file(name)
  #first save SVG
  name += ".svg" unless name.match(/svg$/)
  File.open(name, "w") do |file|
    file.write build
  end

  #convert to JPG and delete the SVG doc
  if(name.match(/jpg|png/))
    #puts "converting..."
    system("nice -n #{@priority} #{@myconvert} -quality 95 #{name} #{name.sub('.svg','')}")
    #system("rm #{name}")
  end
end

def draw_border
  #black out around margin
  rect 0,0,@width,@margin, @background
  rect 0,0,@margin,@height, @background
  rect @width-@margin,0,@margin,@height, @background
  rect 0,@height-@margin,@width,@margin, @background
end

#alias for 'puts' but could be customised later
def debug(msg)
  puts msg if @debug
end

def alert
  `echo -ne '\007'` #terminal bell
end

#add text to the image
def label(words, x,y,size=12, color="fff")
    @yield += %Q!<text x="#{x}" y="#{y}" font-family="Helvetica" font-style="normal" font-size="#{size}px" fill="##{color}">#{words}</text>\n!
end

#convenience method to follow our "verb" convention
def sign(color="fff",text="Peter Kappus")
  signature color,text
end

def signature(color="fff",text="PETER KAPPUS")
  label text, @margin, @height-(@margin*0.7),@margin/4,color
end
