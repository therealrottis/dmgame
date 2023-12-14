class Path
  @@paths = []

  def self.dir_to_key(dir)
    Config.get(case dir
    when 0 then :key_right
    when 2 then :key_down
    when 4 then :key_left
    when 6 then :key_up
    when 1 then :key_rd
    when 3 then :key_ld
    when 5 then :key_lu
    when 7 then :key_ru
    end)
  end

  def self.h(a, b)
    MathHelpers.chebyshev_distance(a, b)
  end

  def self.a_star(pos1, pos2)
    nodes = [Node.new(pos1, 0, h(pos1, pos2))]
  end

  def initialize(pos1, pos2)
    @path = Path.a_star(pos1, pos2)
  end

  RIGHT = 0
  DOWN = 2
  LEFT = 4
  UP = 6
  RIGHT_DOWN = 1
  LEFT_DOWN = 3
  LEFT_UP = 5
  RIGHT_UP = 7
end
