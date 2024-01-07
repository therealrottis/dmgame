["time", "entity", "engine",
  "config", "console", "inventory", 
  "reader", "converter", "input", 
  "math_helpers", "menus", "wall", 
  "room", "virtual_weapon", "item", 
  "path", "benchmark"].each do |codefile|
  require_relative("code/" + codefile)
end

["curses", ["priority_queue_cxx", "fc"]].each do |dependency, *rest|
  begin
    gem dependency
  rescue Gem::LoadError => e
    puts("Missing dependency \"#{dependency}\". Attempting install... (may take multiple minutes, be patient)")
    Gem.install(dependency)
    gem dependency
  end
  # normally gem name is same as what is used in require
  # not for priority_queue
  require (rest.length == 0 ? dependency : rest[0])
end
puts("Dependencies loaded.")

def get_time
  GameTime.true_time
end

def do_something(text)
  print(text+"...")
  st = get_time
  yield
  print("done in #{((get_time-st).round(3)*1000).to_i}ms.\n")
end

def resolution_check
  if Curses.cols < 80
    puts("The game can't run properly on too low resolutions")
    puts("Increase your console width to above 80")
    exit()
  end
  if Curses.lines < 20
    puts("The game can't run properly on too low resolutions")
    puts("Increase your console height to above 20")
    exit()
  end
end

def main
  puts("Starting game...")
  st = get_time

  do_something("Initializing engine") { GameEngine.init }
  resolution_check
  do_something("Loading config") { Config.load_config }
  do_something("Loading items") { Item.load_items }
  do_something("Loading entities") { Entity.load_entities }

  puts("Game started in #{((get_time-st).round(3)*1000).to_i}ms.")

  begin
    last_selected = 0
    while true
      Curses.clear
      case Menus.main_menu(last_selected)
      when "quit" 
        exit
      when "settings" 
        Menus.settings
        last_selected = 1
      when "about"
        Menus.about
        last_selected = 2
      when "play" 
        game
        last_selected = 0
      end
    end
  ensure
    Curses.close_screen
    if Config.get(:debug_mode)
      puts("debug information:")
      Benchmark.print_times_spent
      Benchmark.display_caches
      Benchmark.print_tick_times
    end
  end
end

def game
  my_room = Room.new([Wall.new([5, 10], [5, 20]), Wall.new([6, 10], [10, 10])])

  GameEngine.clear

  if !Entity.player_exists?
    Entity.new(:player, 15, 15)
  end

  char = ""
  string = ""
  while char != 3 # 3 == ctrl+c
    if char.class == String
      char = char.downcase
    end
    if char == "/" || char == Config.get(:key_chat)
      Curses.timeout = -1
      GameEngine.alert = "PAUSED"
      val = ""
      val = Console.get_command # pauses time
      if val == :want_exit
        return
      end
    elsif !char.nil? # nil means nonblocking returned nothing
      Entity.player.action(char)
    else # returned nothing, let's try moving player from buffer
      if !Entity.player.action_buffer.nil? && Entity.player.move_available_at >= GameTime.tick_time
        Entity.player.action(Entity.player.action_buffer)
        Entity.player.action_buffer = nil
      end
    end
    
    if GameTime.tick?
      if Config.get(:debug_mode)
        GameTime.get_tick_time
        Benchmark.time_spent(:entity_movements) do
          Entity.movements
        end
        Benchmark.time_spent(:render) do
          GameEngine.render
        end
        Benchmark.tick
      else
        GameTime.get_tick_time
        Entity.movements
        GameEngine.render
      end
    end

    Curses.timeout = GameTime.tick_timeout # ms
    char = Curses.getch
  end
end

main