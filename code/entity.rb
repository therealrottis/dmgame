class Entity
  @@id = 0
  @@entities = Array.new()
  @@old_entities = Set.new()
  @@entitytypes = nil
  @@entityprops = nil
  @@player = nil

  attr_accessor :inventory, :weapon
  attr_reader :x, :y, :id, :type, :last_enemy, :last_move_at

  def self.entities
    @@entities
  end

  def self.old_entities
    @@old_entities
  end

  def self.clear_old_entities
    @@old_entities = Set.new
  end

  def self.exists?(type)
    return @@entitytypes.include?(type.to_sym)
  end

  def self.player
    @@player
  end

  def self.add_entity(entity)
    #@@entities.insert(@@entities.bsearch_index { |other_entity| other_entity.last_move_at >= entity.last_move_at } || 0, entity)
    # antioptimization...
    @@entities << entity
  end

  def check_weapon
    if !own?(@weapon) || @weapon.count <= 0
      @weapon = nil
    end
  end

  def move_if_available
    return if @type == :player
    if property(:volatile)
      explode_if_can
    end
    #     v :stop_iter (antioptimisation)
    return if @last_move_at > Process.clock_gettime(Process::CLOCK_MONOTONIC)
    return if property(:no_move)
    @last_move_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) + cooldown + rand(0..10)/50.to_f
    #@@entities.delete(self)
    #Entity.add_entity(self)
    if MathHelpers.true_distance(self.pos, @@player.pos) <= view_distance# && @@player.los?(self)
      action(Config.get(:key_right))
    end
  end

  def explode_if_can
    return unless property(:volatile)
    if @last_move_at < Process.clock_gettime(Process::CLOCK_MONOTONIC)
      explode
      die
    end
  end

  def view_distance
    property(:view_distance) || 10
  end

  def self.movements
    @@entities.each do |entity|
      return if entity.move_if_available == :stop_iter
    end
  end

  def cooldown
    property(:cooldown) or 1
  end

  def aim_toward
    ## buf[2]
    ## if buf adjacent: dir = diag
    ## else: dir = buf[-1]
    throw "NotImplementedError: entity.aim_torward"
  end

  def action(char)
    return if @reject_move
    ogx = @x
    ogy = @y
    @@old_entities << [y, x]
    case char
    when Config.get(:key_up)
      @y -= 1
    when Curses::KEY_UP
      @y -= 1
    when Config.get(:key_down)
      @y += 1
    when Curses::KEY_DOWN
      @y += 1
    when Config.get(:key_left)
      @x -= 1
    when Curses::KEY_LEFT
      @x -= 1
    when Config.get(:key_right)
      @x += 1
    when Curses::KEY_RIGHT
      @x += 1
    when Config.get(:key_interact)
      found_entity = nil
      @@entities.each do |entity|
        if MathHelpers.fast_distance(entity.pos, pos) < 3 && entity != self
          if entity.interactable?
            found_entity = entity
            break
          end
        end
      end

      if !found_entity.nil?
        interact(found_entity)
      end
    when Config.get(:key_attack)
      return if @weapon.nil?
      return @weapon.use if @weapon.property(:no_melee)
      return if @next_attack_at > Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @next_attack_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @weapon.cooldown
      attack_entities = []
      @@entities.each do |entity|
        if (d = MathHelpers.fast_distance(entity.pos, pos)) < @weapon.range && entity != self && !entity.property(:invulnerable)
          attack_entities << [entity, d]
          #break if attack_entities.length >= @weapon.hits
          # grayed out: want to attack closest entity, not entity with lowest id
        end
      end
      
      attack_entities.sort_by { |a, b| b } # b = distance
      attack_entities = attack_entities.map { |a, _| a }
      
      if attack_entities.length > @weapon.hits
        attack_entities = attack_entities[0...(@weapon.hits)]
      end
      attack_entities.each do |entity|
        attack(entity)
      end
    end
    
    if (ogx != @x || ogy != @y)
      if @type == :player && (ogx != @x || ogy != @y)
        GameEngine.move_if_necessary(pos)
      end
      if property(:has_collision)
        Room.cache_remove(ogy, ogx)
      end
      if Room.walls_collide(@y, @x)
        @y = ogy
        @x = ogx
      end
    end
  end

  def interactable?
    return property(:lootable) || false
  end

  def interact(entity)
    if entity.property(:lootable)
      pick_up(entity)
    elsif entity.property(:test)
    end
  end

  def attack(entity)
    if own?(@weapon)
      @last_enemy = entity
      entity.take_damage(@weapon.damage(entity.pos))
    else
      @weapon = nil
    end
  end

  def take_damage(damage)
    if !property(:invulnerable)
      if @type == :player
        Curses.flash
      end
      @health -= damage
      if @health <= 0
        die
      end
    end
  end

  def explode
    return unless property(:volatile)
    @weapon = VirtualWeapon.new(self)
    action(Config.get(:key_attack))
    @weapon = nil
    Entity.new(:explosion_effects, *self.pos, :explosion_radius => property(:explosion_radius))
    die
  end

  def die
    unless property(:no_drop)
      Entity.new(:loot, @x, @y, :inventory => @inventory.random_declutter)
    end
    if @type == :player
      GameEngine.show_at_top("Game over")
      @reject_move = true # doesnt need to be for all entities: others aren't looped through anymore (ln +2)
    end
    @@entities.delete(self)
  end

  def pick_up(other)
    self.inventory += other.inventory 
    other.inventory = Inventory.new()
    @@entities.delete(other)
    @@old_entities << other.pos
  end

  def pos
    [y, x]
  end

  def timer_to_char
    (@next_attack_at - Process.clock_gettime(Process::CLOCK_MONOTONIC)).to_i.to_s
  end

  def char
    timer_to_char if property(:char_from_timer)
    property(:char) || "."
  end

  def self.next_char(char)
    case char
    when "-" then "="
    when "=" then "¤"
    when "¤" then "#"
    when "#" then "@"
    when "@" then "#"
    end
  end

  def time_until_next_attack
    num = @next_attack_at - Process.clock_gettime(Process::CLOCK_MONOTONIC)
    if num <= 0
      return ""
    else
      bar_size = 10
      str = "-"*(num*5).to_i
      while str.length > 2 * bar_size
        str[0...10] = Entity.next_char(str[0]) * bar_size
        str = str[0...-10]
      end
      if str.length > bar_size
        str[0...(str.length - bar_size)] = Entity.next_char(str[0]) * (str.length - bar_size)
        str = str[0...10]
      end
      return str + " "
    end
  end

  def set_inventory(inventory)
    @inventory = inventory
    inventory.owner = self
  end

  def property(prop)
    if @@entityprops[@type].nil?
      throw "UndefinedTypeException: #{@type} is not entity"
    end
    @@entityprops[@type][prop]
  end

  def initialize(type, x, y, **flags)
    @id = @@id
    @@id += 1
    @x = x.to_i
    @y = y.to_i
    c_iter = 1
    var = 0

    # makes so stuff doesnt spawn in walls: goes in spiral pattern
    # 7 8 9 10...
    # 6 1 2 
    # 5 4 3
    while Room.walls_collide(@y, @x)
      if var == 0
        @x += c_iter
      elsif var == 1
        @y += c_iter
      elsif var == 2
        @x -= @c_iter
      elsif var == 3
        @y -= @c_iter
      end
      if var % 2 == 1
        c_iter += 1
      end
      var += 1
      var %= 4
    end

    @type = type.to_sym
    @next_attack_at = 0
    if property(:volatile)
      @last_move_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) + property(:explosion_timer)
    else
      @last_move_at = 0
    end
    @last_enemy = nil
    Entity.add_entity(self)

    if type == :player
      @@player = self
    end
    
    case property(:inventory)
    when nil then set_inventory(flags[:inventory] || Inventory.new)
    when "random" then set_inventory(Inventory.random_inventory)
    else
      set_inventory(Inventory.random_inventory(property(:inventory).to_sym))
    end

    @health = (property(:health) or 10)
    @max_health = @health

    case property(:weapon)
    when nil
      @weapon = nil
    else
      a = Item.new(property(:weapon))
      @inventory << a
      @weapon = a
    end
  end

  def inventory_text
    return @inventory.show_items_array
  end

  def debug_display
    puts("entity #{@id} at #{@x}, #{@y}, inventory=#{@inventory.map {|x|x.to_s}.to_s}")
  end

  def hp_display(bar_size)
    if @hp_display_cache.nil? || @oldhps != [@health, @max_health]
      strend = " (#{@health}/#{@max_health})" 
      strstart = @type == :player ? "Your HP:  " : "Enemy HP: "
      bar_size -= strend.length + strstart.length
      if @health > 0
        str = "#" * (bar_size * (@health.to_f / @max_health)).to_i
        str += "." * (bar_size - str.length)
      else
        str = "." * bar_size
      end
      @hp_display_cache = strstart +  str + strend
      @oldhps = [@health, @max_health]
    end
    return @hp_display_cache
  end

  def own?(item)
    return true if item.class == VirtualWeapon
    return if item.nil?
    @inventory == item.inventory
  end

  def self.owns?(entity, item)
    entity.own?(item)
  end

  def to_s
    @char
  end

  def self.player_exists?
    return !get_player.nil?
  end  
    
  def self.get_player
    @@entities.each do |entity|
      if entity.type == :player
        return entity
      end
    end
    nil
  end

  def self.load_entities
    @@entitytypes, @@entityprops = Reader.load_data("entities")
  end

  def player_select_weapon
    return if @type != :player
    @weapon = Menus.weapon_menu
    GameEngine.clear
  end

  def set_weapon(name)
    @weapon = @inventory.item(name)
  end
end