module Config
  def self.load_config
    @@config = Reader.load_config
    @@version = Reader.get_version
  end

  def self.save_config(hash)
    str = ""
    hash.each do |key, value|
      str += key.to_s + "=" + value.to_s + "\n"
    end
    File.open(Reader::CONFIG_FOLDER + "config.cfg", "w") do |file|
      file.write(str)
    end
  end

  def self.get(key = nil)
    if key.nil?
      return @@config
    end
    return @@config[key]
  end

  def self.not_allowed(key)
    return !@@config[key]
  end

  def self.allowed(key)
    return @@config[key]
  end

  def self.version
    @@version
  end
end