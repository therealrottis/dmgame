module GameTime
  @@paused_time = 0
  
  def self.time
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - @@paused_time
  end

  def self.pause_time
    @@pause_start_time = time()
  end

  def self.unpause_time
    @@paused_time += time() - @@pause_start_time
    @@pause_start_time = nil
  end
end