module Converter
  def self.convert_array(value, **flags)
    # flags:
    #
    # forbid_subarrays: only split on "," if array depth is 0, don't make subarrays
    # example usage: "abc,def=5,ghi=[1,2]" should 
    # with flag:    ["abc", "def", "ghi=[1,2]"]
    # without flag: ["abc", "def", "ghi=", [1, 2]]
    #
    # keep_extra_level: don't remove extra array depth level, used when passing arrays of form "a, b, c" without outermost []
    newval = []
    cque = ""
    arrdepth = 0
    cur = newval
    value.chars do |char|

      if char == "["
        arrdepth += 1
        if flags[:forbid_subarrays]
          cque += char # if we don't want subarrays, keep the brackets
        else
          cur << []
          cur = cur[-1]
        end

      elsif char == "," && (!flags[:forbid_subarrays] || (flags[:forbid_subarrays] && arrdepth == 0))
        # if char == divider and (subarrays allowed or (subarrays disallowed and not currently in subarray))
        if flags[:forbid_subarrays] # if no subarrays, never make a subarray
          cur << convert(cque, :no_array => true)
        else
          cur << convert(cque)
        end
        cque = ""

      elsif char == "]"
        arrdepth -= 1
        if flags[:forbid_subarrays]
          cque += char # if we don't want subarrays, keep the brackets
        else
          if cque.length > 0 # if array is "[]" then it should have 0 elements, don't add an empty ""
            cur << convert(cque)
            cque = ""
          end
          cur = newval
          arrdepth.times { cur = cur[-1] }
        end

      else # others
        cque += char
      end
    end
    if cque != "" && flags[:keep_extra_level] # keep extra level is used when value = "a,b,c,d" without ending ], so last is always missed
      cur << cque
      cque = ""
    end
    
    if arrdepth != 0 || cque != ""
      puts("parseerror: >#{value}<, arrdepth=#{arrdepth}, cque=#{cque}")
      puts("retval: #{flags[:keep_extra_level] ? "" : "(has extra arr level)"} >#{newval}<")
    end
    value = newval # remove one arr depth, newval = [] makes one too many
    value = value[0] unless flags[:keep_extra_level]
    
    return value
  end

  def self.convert(value, **flags)
    # flags: 
    #
    # no_array: always return before array code
    #
    # other flags get passed to convert_array
    if value.nil?
      return nil
    end

    if value.class == Array
      puts("why are you converting an array?")
      p value
      return
    end
    
    if value.include?(".")
      begin
        return Float(value)
      rescue ArgumentError, TypeError
        true
      end
    end

    begin
      return Integer(value)
    rescue ArgumentError, TypeError
      true
    end
    
    if value == "true"
      return true
    elsif value == "false"
      return false
    end

    return value if flags[:no_array] # return before array code if we don't want an array
    return value unless value.include?("[") || value.include?(",") # catch strings

    return convert_array(value, **flags)
  end
  
  def self.compact_number(num)
    if num < 0
      sign = -1
      num *= -1
    else
      sign = 1
    end
    postfixes = ["", "k", "M", "B", "Qu", "Qi"]
    postfix_ind = 0
    while num >= 1000
      postfix_ind += 1
      num /= 1000
    end
    return (sign*num).to_s + postfixes[postfix_ind]
  end
  
  def self.substitute(array, props)
    fill_replace_char = props[:fill_replace_char] ||  throw("converter.substitute: f_r_c not defined")
    fill_char = props[:fill_char] ||                  throw("converter.substitute: f_c not defined")
    fill_width = props[:fill_width] ||                throw("converter.substitute: f_wid not defined")
    array.each do |row|
      if row.include?(fill_replace_char)
        row_width = row.length
        if row_width > fill_width
          puts("minor: converter.substitute; row_wid not enough for row #{row}")
          next
        end
        row.gsub!(fill_replace_char, fill_char * (fill_width - row_width))
      end
    end
    array
  end

  def self.dir_to_sym(dir)
    case dir
    when 0 then :key_right
    when 2 then :key_down
    when 4 then :key_left
    when 6 then :key_up
    when 1 then :key_rd
    when 3 then :key_ld
    when 5 then :key_lu
    when 7 then :key_ru
    end
  end

  def self.dir_to_key(dir)
    Config.get(dir_to_sym(dir))
  end

  def self.dir_to_yx_arr(dir)
    case dir
    # straight lines
    when 0 then [0, 1] # r
    when 1 then [1, 1] # d
    when 2 then [1, 0] # l
    when 3 then [1, -1] # u

    # diags
    when 4 then [0, -1] # rd
    when 5 then [-1, -1] # ld
    when 6 then [-1, 0] # lu
    when 7 then [-1, 1] # ru
    
    # 30 deg diags
    when 8 then [2, 1] # rrd 
    when 9 then [1, 2] # rdd
    when 10 then [-1, 2] # ldd
    when 11 then [-2, 1] # lld
    when 12 then [-2, -1] # llu
    when 13 then [-1, -2] # luu
    when 14 then [1, -2] # ruu
    when 15 then [2, -1] # rru
    end
  end

  def self.dir_to_normalized_yx_arr(dir)
    step = dir_to_yx_arr(dir)
    if dir < 8 # 8 squares around
      if dir % 2 == 1 # only affect if diag 
        step = step.map { |n| n * 0.7 } # 1 / (sqrt (1**2 + 1**2))
      end
    elsif dir < 16 # double diag
      step = step.map { |n| n * 0.45 } # 1 / (sqrt (1**2 + 2**2))
    end
    step
  end

  def self.path_reverse(array)
    array.map { |n| (n + 4) % 8 }
  end

  def self.private_crunch_path(array)
    last = array[0]
    newarr = []
    array[1..-1].each do |elem|
      if (elem - last).abs == 4 # straight across
        last = 100 # skip next check
      else
        newarr << last
        last = elem
      end
    end
    newarr
  end
  private_class_method :private_crunch_path

  def self.crunch_path(array)
    last_len = 0
    until last_len = array.length
      last_len = array.length
      array = private_crunch_path(array)
    end
    return array
  end

  def self.to_time(value)
    value = 0 if value.nil?
    seconds = value.floor
    milliseconds = ((value * 1000) % 1000).floor
    microseconds = ((value * 1000000) % 1000).floor
    
    minutes = (value / 60.0).floor
    hours = (minutes / 60.0).floor
    
    if hours >= 2
      return "#{hours}h, #{minutes}min"
    elsif minutes >= 5
      return "#{minutes}min, #{seconds}s"
    elsif seconds >= 5
      return "#{seconds}s, #{milliseconds}ms"
    elsif milliseconds >= 1
      return "#{milliseconds}ms #{microseconds}us"
    else#if microseconds >= 1
      return "#{microseconds}us"
    end
  end
end
