require 'ruby2d'

set width: 1920
set height: 1080
set background: '#066b46'

## Här skapas en klass som får olika attribut
class Player
  attr_accessor :x, :y, :speed, :image, :rotation

## Här får spelarna en bredd, en höjd, en bild och positioner. Här förklaras även rotationen som bilen har från början och starthastigheten.
  def initialize(image_path, x, y, road_rectangles, road_circles, mountain)
    @image = Image.new(image_path, width: 50, height: 100, x: x, y: y)
    @rotation = 270
    @image.rotate = @rotation
    @speed = 0
    @road_rectangles = road_rectangles
    @road_circles = road_circles
    @mountain = mountain
  end

#Här är funktionen som får bilarna att röra på sig. Med en matematisk formel beräknas rotationen på bilen vilket blir svängningen på bilen. Bilen tilldelas nya x och y värden via denna funktion.
  def move
    angle_in_radians = @rotation * Math::PI / 180
    new_x = @image.x + Math.sin(angle_in_radians) * @speed
    new_y = @image.y - Math.cos(angle_in_radians) * @speed
 
    # Här kollas det om bilen är i rektangeln, om den är det så reduceras hastigheten med 0.5, vilket gör att det blir ett finare stopp för bilen istället för att den stannar direkt.
    if inside_rectangle_coords?(new_x, new_y, @mountain)
      @speed *= 0.5  # Reduce speed to simulate bounce/slam
    else
      @image.x = new_x
      @image.y = new_y
    end
  
    # Apply friction, but ensure speed doesn't go below 0
    # Här är friktionen som gör att bilen inte stannar direkt, men att bilen inte kan få negativ hastighet då bilen då hade börjat backa bakåt.
    if @speed > 0
      @speed -= 0.5
    elsif @speed < 0
      @speed += 0.5
    end
  end

# Här skapas funktionen som definerar accelerationen på bilen. Här sätts maxhastigheten. 
def accelerate(amount, max_speed = 8)
  max_speed = outside_road? ? 3 : max_speed
  @speed += amount if @speed < max_speed
end

# Här skapas funktionen som minskar hastigheten men att den inte kan minska med hur mycket som helst då vi vill att bilen ska kunna backa, men inte hur snabbt som helst. Så här sätts även min-hastigheten.
def decelerate(amount, min_speed = -4)
  @speed -= amount if @speed > min_speed
end

# Här skapas en funktion som bestämmer om bilen kan rotera stillaståenede till vänster eller inte. Nu kan man svänga sekunden bilen rör på sig, men står man helt still så kan man inte svänga. Detta gör det mer realistiskt då en bil i verkligheten inte kan svänga runt i en hel cirkel stillastående.
def rotate_left(amount)
  if @speed.abs >= 0.8
    if @speed > 0
      @rotation -= amount
    else
      @rotation += amount
    end
  end
  @image.rotate = @rotation
end

# Detta är exakt samma kod som ovan fast att rotationen är åt höger istället för vänster som funktionen ovan var.
def rotate_right(amount)
  if @speed.abs >= 0.8 ##
    if @speed > 0
      @rotation += amount
    else
      @rotation -= amount
    end
  end
  @image.rotate = @rotation
end
  # Här skapas en funktion som kollar om bilarna är på vägen eller inte. Här används funktionerna som jag förklarat ovan.
  def outside_road?
    !@road_rectangles.any? { |rect| inside_rectangle?(@image, rect) } &&
    !@road_circles.any? { |circle| inside_circle?(@image, circle) }
  end

  def inside_rectangle?(image, rect)
    image.x.between?(rect.x, rect.x + rect.width) && image.y.between?(rect.y, rect.y + rect.height)
  end

  def inside_circle?(image, circle)
    Math.sqrt((image.x - circle.x)**2 + (image.y - circle.y)**2) < circle.radius
  end
end

def inside_rectangle_coords?(x, y, rect)
  x.between?(rect.x, rect.x + rect.width) && y.between?(rect.y, rect.y + rect.height)
end




# Create road_rectangles
road_rectangles = []
road_rectangle_positions = [[250, 117, 1420, 267], [250, 697,1420, 267], [115, 250,267, 580],[1535, 250,267, 580]]
road_rectangle_positions.each do |x, y, width, height|
  road_rectangles << Rectangle.new(x: x, y: y, width: width, height: height, color: '#6d6462')
end

# Create road_circles
road_circles = []
road_circle_positions = [[250, 250,135], [1670, 830,135], [250, 830,135],[1670, 250,135]]
road_circle_positions.each do |x, y, radius|
  road_circles << Circle.new(x: x, y: y, radius: radius, color: '#6d6462')
end

# Detta är blocket i mitten som man inte kan köra igenom. Jag kallar den för mountain.
mountain = Rectangle.new(x: 510, y: 445, width: 900, height: 190, color: 'white')
Rectangle.new(x: 515, y: 450, width: 890, height: 180, color: '#5d5756')

# Start/Finish line (you can reposition if needed)
# Här skapas en checkpoint, om man åker över checkpointen som är på andra sidan banan så kan man få poäng. Annars kan man inte få poäng. Detta gör att man inte kan åka fram och tillbaka över linjen och få 3 laps direkt.
finish_line = Rectangle.new(x: 960, y: 697, width: 10, height: 267, color: 'white')
checkpoint = Rectangle.new(x: 960, y: 117, width: 10, height: 267, color: '#6d6462')

# Lap counters
player1_laps = 0
player2_laps = 0

# Track if they've crossed already (so they can't spam laps)
player1_crossed = false
player2_crossed = false

# Winning flag
winner = nil

player1_checkpoint_reached = false
player2_checkpoint_reached = false


# Create players
player1 = Player.new('img/player2new.png', 1010, 740, road_rectangles, road_circles, mountain)
player2 = Player.new('img/player1new.png', 1010, 820, road_rectangles, road_circles, mountain)
car_rotation_speed = 3

# Här så får varje rörelse en egen knapp. Så om man tex trycker på "w" så åker bilen frammåt.
on :key_held do |event|
  case event.key
  when 'w' then player1.accelerate(1.5, 8)
  when 's' then player1.decelerate(2, -4)
  when 'a' then player1.rotate_left(car_rotation_speed)
  when 'd' then player1.rotate_right(car_rotation_speed)

  when 'up' then player2.accelerate(1.5, 8)
  when 'down' then player2.decelerate(2, -4)
  when 'left' then player2.rotate_left(car_rotation_speed)
  when 'right' then player2.rotate_right(car_rotation_speed)
  end
end

# Detta är texten som kommer upp när en spelare har vunnit. Det finns två varianter som kan ske, antingen vinner blå eller röd bil. Här bestäms även positionerna på texterna.
lap_text1 = Text.new("Blue car Laps: 0", x: 50, y: 20, size: 25, color: 'white')
lap_text2 = Text.new("Red car Laps: 0", x: 50, y: 50, size: 25, color: 'white')
winner_text = Text.new("", x: 670, y: 15, size: 90, color: 'yellow')

update do
# Lap detection for player 1
# Player 1 checkpoint detection
if inside_rectangle_coords?(player1.image.x, player1.image.y, checkpoint)
  player1_checkpoint_reached = true
end

# Lap detection for player 1
if inside_rectangle_coords?(player1.image.x, player1.image.y, finish_line) && !player1_crossed && player1_checkpoint_reached
  player1_laps += 1
  player1_crossed = true
  player1_checkpoint_reached = false
  puts "Blue car Lap: #{player1_laps}"
end

# Reset crossing status if not on the finish line
unless inside_rectangle_coords?(player1.image.x, player1.image.y, finish_line)
  player1_crossed = false
end

# Lap detection for player 2
if inside_rectangle_coords?(player2.image.x, player2.image.y, checkpoint)
  player2_checkpoint_reached = true
end

# Lap detection for player 2
if inside_rectangle_coords?(player2.image.x, player2.image.y, finish_line) && !player2_crossed && player2_checkpoint_reached
  player2_laps += 1
  player2_crossed = true
  player2_checkpoint_reached = false
  puts "Red car Lap: #{player2_laps}"
end

# Reset crossing status if not on the finish line
unless inside_rectangle_coords?(player2.image.x, player2.image.y, finish_line)
  player2_crossed = false
end


  # Win check
  #Här kollas det om någon har vunnit, det vill säga när en spelare fått 3 poäng som innebär 3 varv. Om tex blå bil får 3 poäng så kommer det upp att blå bil vann och vise versa.
  if winner.nil?
    if player1_laps >= 3
      winner = "Blue car"
      puts "🏁 #{winner} wins!"
    elsif player2_laps >= 3
      winner = "Red car"
      puts "🏁 #{winner} wins!"
    end
  end
  # Här är texten som visar hur många varv som man åkt.
  lap_text1.text = "Blue car Laps: #{player1_laps}"
  lap_text2.text = "Red car Laps: #{player2_laps}"

  if winner
    winner_text.text = "#{winner} WINS!"
  end
  # Om ingen har vunnit så kommer det gå att köra bilarna, men när man vunnit så kan man inte röra på sig, men man kan snurra runt, bara för att det ser roligt ut :).
  unless winner
    player1.move
    player2.move
  end

end

show

