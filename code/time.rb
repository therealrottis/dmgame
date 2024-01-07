module GameTime
  @@paused_time = 0.0 # s
  @@pause_start_time = nil
  @@pause_depth = 0
  @@last_tick_length = 0 # ms
  @@tick_behind = 0.0 # ms
  @@tick_time = nil # s
  @@last_tick_time = 0 # s, only used in self.tick?, not critical 

  def self.true_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def self.time
    true_time - @@paused_time - paused_for
  end
  
  def self.get_tick_time
    t = time
    @@last_tick_time = @@tick_time
    @@last_tick_length = (t - (@@tick_time || t)) * 1000

    if @@last_tick_length > TIMEOUT
      @@tick_behind += @@last_tick_length - TIMEOUT
    elsif @@tick_behind > 0
      @@tick_behind -= TIMEOUT - @@last_tick_length
    end
    @@last_tick_relative_length = @@last_tick_length / TIMEOUT

    if @@tick_behind > 5000
      puts("WARN: Running #{Converter.to_time(@@tick_behind / 1000)} behind, if this was unintentional please report this")
    end

    @@tick_time = t
  end

  def self.tick_time # s
    @@tick_time
  end
  
  def self.tick? # has enough time passed since last tick to warrant a new tick?
    return true if @@last_tick_time.nil?
    return (time - @@last_tick_time) >= TIMEOUT_SEC
  end

  def self.last_tick_length # ms
    @@last_tick_length
  end

  def self.last_tick_relative_length
    @@last_tick_relative_length
  end

  def self.pause_time
    @@pause_depth += 1
    return if @@pause_depth > 1 # already paused before
    @@pause_start_time = true_time
  end

  def self.unpause_time
    @@pause_depth -= 1
    return if @@pause_depth > 0 # game still not unpaused
    @@paused_time += true_time - @@pause_start_time
    @@pause_start_time = nil
  end

  def self.paused_for
    return 0 if @@pause_start_time.nil?
    @@pause_start_time - true_time
  end

  private_class_method :pause_time, :unpause_time
  # forces pause and unpause to be in pairs

  def self.while_paused
    begin
      pause_time
      yield
    ensure
      unpause_time
    end
  end

  def self.tick_timeout
    if @@tick_behind > 0
      return 0 # nonblocking, catch up as quickly as possible before doing anything
    else
      return MathHelpers.if_positive(TIMEOUT - @@last_tick_length)
    end
  end

  TICKRATE = 20 # per second
  TIMEOUT = 1000 / TICKRATE # ms
  TIMEOUT_SEC = TIMEOUT / 1000.0
end