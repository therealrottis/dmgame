class VirtualWeapon
  attr_reader :range, :hits, :cooldown

  def damage(other_entity_position)
    if @owner.property(:volatile)
      (MathHelpers.explosion_dmg_multiplier(other_entity_position, @owner.pos, @range) * @damage).to_i
    else
      puts("virtual_weapon.damage not defined for #{@owner.type}")
      return 1
    end
  end

  def property(prop)
    return @properties[prop]
  end

  def initialize(entity)
    # get weapon stats from entity props
    # entity is usually explosive (mby gun or bow when implemented)
    if entity.nil? # only comes up when /spawning stuff
      entity = Entity.player
    end
    @owner = entity
    @properties = {}
    if entity.property(:volatile)
      @range = entity.property(:explosion_radius) || 1
      @hits = entity.property(:explosion_hits) || 1
      @damage = entity.property(:explosion_damage) || 5
      @cooldown = 0 # cd not needed: only explodes once
    else
      puts("noti mplemente (VirtualWeapon.initialize())")
    end
  end
end