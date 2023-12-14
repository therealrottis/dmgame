module Config
  def self.load_config
    @@config = Reader.load_config
    secret_config = {
      :key_ru => "ru",
      :key_lu => "lu",
      :ley_rd => "rd",
      :key_ld => "ld"
      } # hidden keys, two letter because only meant to be used in non-player actions
    secret_config.each do |key, value|
      @@config[key] = value
    end
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