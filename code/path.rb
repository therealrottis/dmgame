class Path
  @@paths = Hash.new()
  attr_reader :path, :goalpos

  def self.h(a, b)
    MathHelpers.chebyshev_distance(a, b)
  end

  def self.a_star(startpos, goalpos)
    return [] if Room.walls_collide(*goalpos)
    nodes = FastContainers::PriorityQueue.new(:min)
    nodes.push([startpos, []], 0 + h(startpos, goalpos))
    already_visited = [startpos]
    # node pos, instructions (cost from start = instructions.length)
    iters = 0
    while iters < 10000 # if more is needed then what even
      pos, instructions = nodes.pop
      #Entity.new(:loot, *pos.reverse) # shows where pathfinder visits
      return instructions if pos == goalpos
      8.times do |dir|
        cur_instr = instructions.dup
        cur_instr << dir
        cpos = MathHelpers.arrsum(pos.dup, Converter.dir_to_yx_arr(dir))
        next if already_visited.include?(cpos)
        already_visited << cpos
        next if Room.walls_collide(*cpos)
        nodes.push([cpos, cur_instr], cur_instr.map{|x|(x%2)*0.001}.sum + cur_instr.length + h(cpos, goalpos))
      end
      iters += 1
    end
    puts("pathfinder iters not sufficient? unable to find path between #{startpos} and #{goalpos}")
    return []
  end

  def self.cached_path(pos1, pos2) # not really useful in current state, probably should improve
    cached = @@paths["#{pos1}=>#{pos2}"]
    return cached unless cached.nil?

    cached = @@paths["#{pos2}=>#{pos1}"]
    return cached unless cached.nil?
    nil
  end

  def self.add_to_cache(pos1, pos2, path)
    @@paths["#{pos1}=>#{pos2}"] = path
    @@paths["#{pos2}=>#{pos1}"] = Converter.path_reverse(path)
  end

  def initialize(pos1, pos2)
    cached = Path.cached_path(pos1, pos2)
    GameEngine.debug("here1")

    if cached.nil?
      GameEngine.debug("before a*")
      @path = Path.a_star(pos1, pos2)
      GameEngine.debug("here2")
      Path.add_to_cache(pos1, pos2, @path)
      GameEngine.debug("here3")
    else
      @path = cached.dup
    end
    GameEngine.debug("here2")
    
    @startpos = pos1
    @goalpos = pos2
    @ind = 0
  end

  def length
    @path.length
  end

  def steps_remaining
    length - @ind - 1 # ind offset
  end

  def to_s
    return "" if @path.nil?
    @path.map { |n| Converter.dir_to_sym(n) }.join(", ")
  end

  def add_to_end(new_goalpos)
    return if @goalpos == new_goalpos
    @path += Path.a_star(@goalpos, new_goalpos)
    @goalpos = new_goalpos
    Path.add_to_cache(@startpos, @goalpos, @path)
  end

  def next
    return nil if @ind >= @path.length
    nval = @path[@ind]
    @ind += 1
    return nval
  end

  def simplify
    @path[ind..-1] = Converter.crunch_path(@path[ind..-1])
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
