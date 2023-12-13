class Inventory
  attr_accessor :owner

  def items
    @items
  end

  def include?(item)
    @items.include?(item)
  end

  def add_items(items)
    items.each do |item|
      add_item(item)
    end
  end

  def <<(item)
    add_item(item)
    self
  end

  def +(items)
    add_items(items)
    self
  end

  def each
    @items.each do |item|
      yield item
    end
  end

  def add_item(newitem)
    @items.each do |item|
      if item.type == newitem.type
        item.combine_stack(newitem)
        return self
      end
    end
  
    @items << newitem
    newitem.inventory = self
    return self
  end

  def delete(item)
    @items.delete(item)
    owner.check_weapon
  end

  def item(name)
    name = name.to_sym
    @items.each do |item|
      if item.type == name
        return item
      end
    end
    return nil
  end

  def initialize(array = Array.new)
    @items = []
    @owner = nil
    add_items(array)
  end

  def show_items_array
    return @items.map(&:to_s)
  end

  def self.random_inventory(resource = nil)
    inv = Inventory.new
    if resource.nil?
      rand(0...5).times do
        inv << Item.new(Item.resources.sample, rand(1..10))
      end
    else
      inv << Item.new(resource, rand(1..10))
    end
    inv
  end

  def length
    return @items.length
  end

  def random_declutter
    newitems = []
    @items.each do |item|
      if item.class != VirtualWeapon && rand(0...100) < item.drop_chance
        newitems << item
      end
    end
    @items = newitems
    self
  end
end