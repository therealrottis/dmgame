module GameTime
  @@paused_time = 0.0
  @@pause_start_time = nil
  @@pause_depth = 0
  
  def self.time
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - @@paused_time
  end

  def self.pause_time
    @@pause_depth += 1
    return if @@pause_depth > 1 # already paused before
    @@pause_start_time = time()
  end

  def self.unpause_time
    @@pause_depth -= 1
    return if @@pause_depth > 0 # game still not unpaused
    @@paused_time += time() - @@pause_start_time
    @@pause_start_time = nil
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
end