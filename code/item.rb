class Item
  attr_reader :type, :count
  attr_accessor :inventory

  @@items = nil
  @@itemprops = nil
  @@resources

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

  def use
    return unless @inventory.owner.own?(self)
    case property(:create_entity_on_use)
    when nil then true
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
    dmg = @@itemprops[@type][:damage]
    if dmg.nil? 
      return 1
    elsif dmg.class == Integer
      return dmg
    else
      return dmg.join("-")
    end
  end

  def property(prop)
    if @@itemprops[@type].nil?
      throw "UndefinedTypeException: #{@type} is not item"
    end
    @@itemprops[@type][prop]
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

  def weapontxt
    if @weapontext.nil?
      @weapontxt = "Weapon: #{@type}, #{damagetxt} damage, #{range} range, #{hits} hits, #{cooldown} cooldown"
    end
    return @weapontxt
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
    @count = count
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
