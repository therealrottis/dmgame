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
end
