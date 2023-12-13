module MathHelpers
  def self.fast_distance(pos1, pos2)
    return (pos1[0] - pos2[0]).abs + (pos1[1] - pos2[1]).abs
  end

  def self.true_distance(pos1, pos2)
    return Math.sqrt((pos1[0] - pos2[0]).abs**2 + (pos1[1] - pos2[1]).abs**2)
  end

  def self.arrsum(arr1, arr2)
    return arr1.zip(arr2).map { |x| x.sum }
  end

  def self.arrsub(arr1, arr2)
    return arr1.zip(arr2).map { |a, b| a - b }
  end

  def self.pytaghoras(a, b)
    return Math.sqrt(a**2 + b**2)
  end

  def self.explosion_dmg_multiplier(pos1, pos2, expl_radius)
    dmg = expl_radius/(true_distance(pos1, pos2))
    if dmg > 1
      dmg = 1
    end
    dmg
  end
end