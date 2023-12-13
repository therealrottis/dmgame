["entity", "engine", "item", 
  "config", "console", "inventory", 
  "reader", "converter", "input", 
  "math_helpers", "menus", "wall", 
  "room", "virtual_weapon"].each do |codefile|
  require_relative("code/" + codefile)
end

["curses"].each do |dependency|
  begin
    gem dependency
  rescue Gem::LoadError => e
    puts("Missing dependency \"#{dependency}\". Attempting install...")
    Gem.install(dependency)
    gem dependency
  end
  require dependency
end
puts("Dependencies loaded.")

def get_time
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

def do_something(text)
  print(text+"...")
  st = get_time
  yield
  print("done in #{((get_time-st).round(3)*1000).to_i}ms.\n")
end

def main
  puts("Starting game...")
  st = get_time
  
  do_something("Initializing engine") { GameEngine.init }
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
      when "play" 
        game
        last_selected = 0
      end
    end
  ensure
    Curses.close_screen 
  end
end

def game
  my_room = Room.new([Wall.new([5, 10], [5, 20]), Wall.new([6, 10], [10, 10])])

  GameEngine.clear

  if Entity.player_exists?
    player = Entity.get_player
  else
    player = Entity.new(:player, 15, 15)
  end

  char = ""
  string = ""
  while char != 3 # 3 == ctrl+c
    if char == "/" || char == Config.get(:key_chat)
      Curses.timeout = -1
      GameEngine.alert = "PAUSED"
      val = Console.get_command(player)
      if val == :want_exit
        return
      end
    else
      player.action(char)
    end
    Curses.timeout = 100

    GameEngine.render
    char = Curses.getch
    Entity.movements
  end
end

main