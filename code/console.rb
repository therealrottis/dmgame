module Console
  def self.needs_cheats(show_message = true)
    if Config.allowed(:cheats)
      yield
    else
      Console.not_allowed_message if show_message
    end
  end

  def self.run(command)
    player = Entity.player
    begin
      command = command.split(" ")
      case command[0]
      when "spawn"
        needs_cheats do
          return unless Entity.exists?(command[1])
          if command.length == 2
            Entity.new(command[1], *player.pos.reverse)
          else
            Entity.new(*command[1..-1])
          end
        end
      when "showcorner"
        GameEngine.render_corners
      when "clear"
        GameEngine.clear
      when "exit"
        return :want_exit
      when "give"
        needs_cheats do
          return unless Item.exists?(command[1])
          player.inventory << Item.new(*command[1..-1])
        end
      when "weaponselect"
        player.player_select_weapon
      when "wpnselect"
        player.player_select_weapon
      when "ws"
        player.player_select_weapon
      when "wpn"
        needs_cheats(false) do
          a = Item.new(*command[1..-1])
          player.inventory << a
        end
        player.set_weapon(command[1])
      when "swarm"
        needs_cheats do
          if command.length < 3
            entity_type = "goblin"
          else
            entity_type = command[2]
          end
          count = 10
          if command.length == 2
            count = command[1].to_i
          end
          count.times do
            entity = nil
            while entity.nil? # rejects entities too close to player
              xd = rand(-15..15)
              yd = rand(-15..15)
              
              npos = player.pos
              npos[0] += xd
              npos[1] += yd
              if MathHelpers.pytaghoras(xd, yd) > 5
                entity = Entity.new(entity_type, *npos.reverse)
              end
            end
          end
        end
      when "fireworks"
        GameEngine.alert = command.to_s
        Curses.refresh
        run("swarm 10 firework")
      when "cam"
        GameEngine.alert = "camera position: " + GameEngine.camera_pos.to_s
      when "cammove"
        if command.length == 2
          command << 0
        end
        GameEngine.set_camera(*MathHelpers.arrsum(GameEngine.camera_pos, command[1..-1].map{ |n| -n.to_i }))
      when "reload"
        Config.load_config
        Item.load_items
        Entity.load_entities
      when "damage"
        player.take_damage(command[1].to_i.abs)
      when "respawn"
        needs_cheats do
          if player.dead?
            ppos = player.pos.reverse  
            Entity.delete_entity(player)            
            Entity.new(:player, *ppos)
          end
        end
      when "path"
        needs_cheats do
          a = Path.new(player.pos, command[1..-1].map(&:to_i))
          GameEngine.alert = a.to_s
        end
      when "pos"
        GameEngine.alert = "player pos: " + player.pos.to_s
      when "heal"
        needs_cheats do
          if Entity.player.dead?
            GameEngine.alert = "respawn first"
          else
            player.heal(command[1].to_i)
          end
        end
      when "items"
        needs_cheats do
          Item.items.each do |item|
            player.inventory << Item.new(item)
          end
        end
      end
    rescue Exception => e
      if Config.get(:debug_mode)
        puts "\"/#{command.join(" ")}\" threw exception: #{e.to_s}\n#{e.backtrace.join("\n")}"
      end
      Console.command_failed_message
    end
  end

  def self.get_command
    string = "" # scope
    GameTime.while_paused do
    string = Input.get_input
    end
    GameEngine.alert = ""
    return if string == :abort
    run(string.delete("/").chomp.downcase)
  end

  def self.not_allowed_message
    GameEngine.alert = "Cheats are not enabled"
  end

  def self.command_failed_message
    GameEngine.alert = "Improper command"
  end
end