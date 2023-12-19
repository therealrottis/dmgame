module Benchmark
  @@cache_hits = Hash.new(0)
  @@cache_misses = Hash.new(0)
  @@time_spent = Hash.new(0.0)
  @@times_ran = Hash.new(0)
  @@last_tick_time = GameTime.true_time
  @@tick_times = []

  def self.cache_hit(cache)
    @@cache_hits[cache] += 1
  end

  def self.cache_miss(cache)
    @@cache_misses[cache] += 1
  end
  
  def self.display_caches
    keys = @@cache_hits.keys + @@cache_misses.keys
    keys.each do |key|
      misses = @@cache_misses[key] || 0
      hits = @@cache_hits[key] || 0
      puts "cache #{key}: hits=#{hits}, misses=#{misses}, hits=#{((hits.to_f/(misses+hits))*100).round}%"
    end
  end

  def self.time_spent(function)
    st = GameTime.true_time
    yield
    @@time_spent[function] += GameTime.true_time - st
    @@times_ran[function] += 1
  end

  def self.print_times_spent
    @@time_spent.each do |key, value|
      puts("time spent in #{key}: #{Converter.to_time(value)}, runs:#{@@times_ran[key]}, avg time per run: #{Converter.to_time(value / @@times_ran[key])}")
    end
  end

  def self.tick
    ctime = GameTime.time
    @@tick_times << ctime - @@last_tick_time
    @@last_tick_time = ctime
  end

  def self.print_tick_times
    return if @@tick_times.length == 0
    @@tick_times.sort!
    floor = (@@tick_times.length * 0.05).to_i
    ceil = (@@tick_times.length * 0.95).to_i
    tick_times_percentile = @@tick_times[floor..ceil]
    true_max = Converter.to_time(@@tick_times.max)
    true_min = Converter.to_time(@@tick_times.min)
    percentile_max = Converter.to_time(tick_times_percentile.max)
    percentile_min = Converter.to_time(tick_times_percentile.min)
    true_avg = Converter.to_time(@@tick_times.sum / @@tick_times.length)
    percentile_avg = Converter.to_time(tick_times_percentile.sum / tick_times_percentile.length)
    true_median = Converter.to_time(@@tick_times[@@tick_times.length / 2])
    percentile_median = Converter.to_time(tick_times_percentile[tick_times_percentile.length / 2])
    puts("tick time stats:")
    puts("absolute stats:")
    puts("min: #{true_min} max: #{true_max} average: #{true_avg} median: #{true_median}")
    puts("5%-95% percentile stats:")
    puts("min: #{percentile_min} max: #{percentile_max} average: #{percentile_avg} median: #{percentile_median}")
  end
end