class Room
  attr_reader :left_wall, :right_wall, :bot_wall, :top_wall, :walls

  @@rooms = []
  @@collision_cache = Hash.new

  def self.rooms
    @@rooms
  end

  def self.walls_collide(y, x)
    if @@collision_cache["#{y}, #{x}"].nil?
      @@collision_cache["#{y}, #{x}"] = false
      @@rooms.each do |room|
        if room.inside_wall?([y, x])
          @@collision_cache["#{y}, #{x}"] = true
        end
      end
    end

    return @@collision_cache["#{y}, #{x}"]
  end

  def self.cache_remove_area(pos1, pos2)
    y1, x1 = pos1
    y2, x2 = pos2

    y2, y1 = y1, y2 if y1 > y2
    x2, x1 = x1, x2 if x1 > x2
    
    (y1..y2).each do |y|
      (x1..x2).each do |x|
        @@collision_cache["#{y}, #{x}"] = nil
      end
    end
  end

  def self.cache_remove(y, x)
    @@collision_cache["#{y}, #{x}"] = nil
  end

  def get_left_wall
    @left_wall = @walls.map(&:left_wall).min
  end

  def get_right_wall
    @right_wall = @walls.map(&:right_wall).max
  end

  def get_top_wall
    @top_wall = @walls.map(&:top_wall).min
  end

  def get_bot_wall
    @bot_wall = @walls.map(&:bot_wall).max
  end

  def top_left
    [@top_wall, @left_wall]
  end

  def bot_right
    [@bot_wall, @right_wall]
  end

  def calc_walls
    get_left_wall
    get_right_wall
    get_bot_wall
    get_top_wall
  end

  def inside?(pos)
    y, x = pos
    return @verti === y && @horiz === x
  end

  def inside_wall?(pos)
    return false if !inside?(pos)
    y, x = pos
    @walls.each do |wall|
      return true if wall.inside?(pos)
    end
    false
  end

  def initialize(walls)
    @walls = walls
    calc_walls
    @horiz = @left_wall..@right_wall
    @verti = @top_wall..@bot_wall

    Room.cache_remove_area(top_left, bot_right)
    @@rooms << self
  end
end