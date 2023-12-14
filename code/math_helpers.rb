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
    distance = true_distance(pos1, pos2)
    
    return 0 if distance > expl_radius # out of range
    return 1 if distance <= 0 # delta = 0, on top of each other

    percentage = distance / expl_radius.to_f 
    # [0..1] distanc from center
    # 1 - percentage = distance from edge
    return 1 - percentage
  end

  def self.if_positive(num)
    return num > 0 ? num : 0
  end

  def self.compact_number(num)
    postfixes = ["", "k", "M", "B", "Qu", "Qi"]
    postfix_ind = 0
    while num >= 1000
      postfix_ind += 1
      num /= 1000
    end
    return num.to_s + postfixes[postfix_ind]
  end
end