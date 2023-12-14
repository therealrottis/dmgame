# reads menu files
module Reader
  def self.read(name)
    name = VIEW_FOLDER + name + ".view"
    if File.exist?(name)
      file = File.read(name)
      file = file.split("--PROPS--\n")
      text = file[0].split("\n")
      proplist = file[1].split("\n").map { |row| row.split("=") }
      props = Hash.new()
      proplist.each do |key, value|
        props[key.to_sym] = Converter.convert(value)
      end
      return [text, props]
    end
    throw "Missing view #{name}"
  end

  def self.read_config(name = "config") # reads config for use in settings
    name = CONFIG_FOLDER + name + ".cfg"
    if File.exist?(name)
      file = File.read(name)
      rows = file.split("\n").map { |row| row.split("=") }
      
      displayrows = config_displayrows_from_rows(rows)

      return [displayrows, rows]
    end
    throw "Config not found: #{name}"
  end

  def self.config_displayrows_from_rows(rows)
    max_key_len = 0
    rows.each do |key, _|
      max_key_len = [max_key_len, key.length].max
    end
    max_key_len += 1

    displayrows = []
    rows.each do |key, value|
      displayrows << key.to_s + " " + "-" * (max_key_len - key.length) + " >" + value.to_s + "<"
      displayrows << ""
    end 
    displayrows
  end

  def self.load_config # loads config for use in code
    config = Hash.new()
    File.read(CONFIG_FOLDER + "config.cfg").split("\n").each do |line|
      key, value = line.split("=").map(&:chomp)
      if value.nil?
        value = " "
      end
      key = key.to_sym
      value = Converter.convert(value)
      config[key] = value
    end
    config
  end

  def self.load_data(file)
    file = DATA_FOLDER + file + ".dat"
    elements = Array.new()
    elementprops = Hash.new()
    items = File.read(file).split("\n")
    items.each do |item|
      name, props = item.delete(" ").split(";")
      name = name.to_sym
      elements << name
      elementprops[name] = Hash.new
      # keep extra level, props is array but has no [] so we want an extra array level
      # only split depth zero, keeps damage=[1,2] from splitting into weird props
      props = Converter.convert(props, :keep_extra_level => true, :forbid_subarrays => true)
      props.each do |prop|
        if prop.include?("=")
          key, value = prop.split("=", 2) # split only by first = if used later
          value = Converter.convert(value)
        else
          key = prop
          value = true
        end
        elementprops[name][key.to_sym] = value
      end
    end
    [elements, elementprops]
  end

  def self.get_version
    return File.read(VERSION_FOLDER + "version")
  end

  DATA_FOLDER = "data/"
  VIEW_FOLDER = "views/"
  CONFIG_FOLDER = ""  
  VERSION_FOLDER = ""
end