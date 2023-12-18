module GameTime
  @@paused_time = 0.0
  @@pause_start_time = nil
  
  def self.time
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - @@paused_time
  end

  def self.pause_time
    unpause_time unless @@pause_start_time.nil? # if paused, pause ei riko paikkoja
    @@pause_start_time = time()
  end

  def self.unpause_time
    return if @@pause_start_time.nil?
    @@paused_time += time() - @@pause_start_time
    @@pause_start_time = nil
  end

  def self.while_paused
    begin
      pause_time
      yield
    ensure
      unpause_time
    end
  end
end