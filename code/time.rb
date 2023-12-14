module GameTime
  def self.time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end