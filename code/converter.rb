class Converter
  def self.convert(value, arr_elems_to_sym = false)
    if value.nil?
      return ""
    end
    if value.include?(".")
      begin
        value = Float(value)
        return value
      rescue ArgumentError
        true
      end
    end
    begin
      value = Integer(value)
    rescue ArgumentError
      true
    end
    if value[0] == "[" && value[-1] == "]"
      value = value[1...-1].split(",")
      if value.length == 1
        value = value[0].split(";").map { |x| convert(x) }
      end
      if arr_elems_to_sym
        value = value.map { |x| x.class == String ? x.to_sym : x }
      end

    elsif value == "true"
      value = true
    elsif value == "false"
      value = false
    end
    return value
  end
end