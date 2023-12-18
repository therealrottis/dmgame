class Item
  attr_reader :type, :count
  attr_accessor :inventory

  @@items = nil
  @@itemprops = nil
  @@resources = nil

  def self.id_to_sym(id)
    return @@items[id]
  end

  def self.items
    @@items
  end

  def self.resources
    @@resources
  end

  def self.sym_to_id(sym)
    return @@items.index(sym)
  end

  def self.exists?(type)
    return @@items.include?(type.to_sym)
  end

  def create_entity_on_use
    case property(:create_entity_on_use)
    when true then return @type
    when nil then return nil
    else
      return property(:create_entity_on_use)
    end
  end

  def toss
    owner = @inventory.owner
    return unless owner.own?(self)
    case property(:create_entity_on_use)
    when nil then true
    else
      Entity.new(:thrown_item, *(owner.pos).reverse, :dir => owner.facing, 
                                                     :walk_distance => owner.throw_strength, 
                                                     :create_entity_on_death => create_entity_on_use, 
                                                     :lifetime => 1,
                                                     :autowalk => true)
    end

    if property(:consume_on_use)
      dec_count(1)
      @inventory.owner.weapon
    end
  end

  def use
    return unless @inventory.owner.own?(self)
    case property(:create_entity_on_use)
    when nil then true
    when true
      Entity.new(@type, *(self.inventory.owner.pos).reverse)
    else
      Entity.new(property(:create_entity_on_use), *(self.inventory.owner.pos).reverse)
    end

    if property(:consume_on_use)
      dec_count(1)
      @inventory.owner.weapon
    end
  end

  def combine_stack(other)
    if type == other.type
      @count += other.count
      other.count = 0
    end
  end

  def dec_count(amount)
    self.count=(@count - amount)
  end

  def count=(value)
    @count = value
    if @count == 0
      @inventory.delete(self) unless @inventory.nil?
      return nil
    end
  end

  def damage(entity_position)
    dmg = property(:damage)
    if dmg.nil? 
      return 1
    elsif dmg.class == Integer
      return dmg
    else
      return rand(dmg[0]..dmg[1])
    end
  end

  def drop_chance
    @@itemprops[@type][:drop_chance] or 0
  end

  def damagetxt
    if @damagetxt_cache.nil?
      dmg = @@itemprops[@type][:damage]
      if dmg.nil? 
        return "1"
      elsif dmg.class == Integer
        return Converter.compact_number(dmg)
      else
        return dmg.map { |n| Converter.compact_number(n) }.join("-")
      end
    end
    @damagetxt_cache
  end

  def property(prop)
    if @@itemprops[@type].nil?
      throw "UndefinedTypeException: #{@type} is not item"
    end
    @@itemprops[@type][prop]
  end

  def stats_array
    ["damage: #{damagetxt}", 
      "range: #{range}", 
      "hits: #{hits}", 
      "cooldown: #{cooldown}s", 
      "type: #{property(:throwable) ? "throwable" : (property(:no_melee) ? "ranged" : "melee")}"]
  end

  def range
    property(:range) or 2
  end

  def hits
    property(:hits) or 1
  end

  def cooldown
    property(:cooldown) or 1
  end

  def weapontxt(text_width)
    if @weapontxt.nil?
      @weapontxt = "#{@type}: #{damagetxt} damage, #{range} range, #{hits} hits, #{cooldown} cooldown"

      bar_width = text_width - @weapontxt.length
      if bar_width <= 5 # means didnt fit, make weapontxt shorter
        @weapontxt = "wpn: #{damagetxt} dmg, #{range} range, #{hits} hits, #{cooldown} cd"
      end

      bar_width = text_width - @weapontxt.length
      if bar_width <= 5 # means didnt fit, make weapontxt shorter
        @weapontxt = "wpn: #{damagetxt} dmg, #{range} range, #{cooldown} cd"
      end

      bar_width = text_width - @weapontxt.length
      if bar_width <= 5 # still didnt fit, make weapontxt even shorter
        @weapontxt = "#{damagetxt} dmg #{range} rg"
      end
    end
    
    bar_width = text_width - @weapontxt.length

    if @inventory.owner.nil?
      cd_bar = ""
    else
      cd_bar = @inventory.owner.time_until_next_attack(bar_width)
    end
    
    return cd_bar + @weapontxt
  end

  def initialize(type, count = 1)
    if type.class == String
      type = type.to_sym
    end
    throw "NoItemError" if !@@items.include?(type)
    if type.class == Symbol
      @type = type
    else
      throw "bad initialize of item object: type=#{type}"
    end
    @count = count.to_i
  end

  def self.load_items
    @@items, @@itemprops = Reader.load_data("items")
    @@resources = []
    @@items.each do |item|
      if @@itemprops[item][:resource]
        @@resources << item
      end
    end
  end

  def to_s
    return "#{@count} #{@type}"
  end

  def length
    return to_s.length
  end
end
