class Wall
  attr_reader :material

  def left_wall
    @pos1[1]
  end

  def right_wall
    @pos2[1]
  end

  def top_wall
    @pos1[0]
  end
  
  def bot_wall
    @pos2[0]
  end

  def top_left
    @pos1
  end

  def bot_right
    @pos2
  end

  def inside?(pos)
    y, x = pos
    return @verti === y && @horiz === x
  end

  def initialize(pos1, pos2)
    y1, x1 = pos1
    y2, x2 = pos2
    if y1 > y2
      y2, y1 = y1, y2
    end
    if x1 > x2
      x2, x1 = x1, x2
    end
    @pos1 = [y1, x1]
    @pos2 = [y2, x2]
    @horiz = x1..x2
    @verti = y1..y2
    @material = "x"
  end
end

