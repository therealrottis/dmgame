class Console
  def self.run(command, player)
    begin
      command = command.split(" ")
      case command[0]
      when "spawn"
        if Config.allowed(:cheats)
          return unless Entity.exists?(command[1])
          if command.length == 2
            Entity.new(command[1], *player.pos.reverse)
          else
            Entity.new(*command[1..-1])
          end
        else
          Console.not_allowed_message
        end
      when "showcorner"
        GameEngine.render_corners
      when "clear"
        GameEngine.clear
      when "exit"
        return :want_exit
      when "give"
        if Config.allowed(:cheats)
          return unless Item.exists?(command[1])
          player.inventory << Item.new(*command[1..-1])
        else
          Console.not_allowed_message
        end
      when "weaponselect"
        player.player_select_weapon
      when "wpnselect"
        player.player_select_weapon
      when "ws"
        player.player_select_weapon
      when "wpn"
        if Config.allowed(:cheats)
          a = Item.new(*command[1..-1])
          player.inventory << a
        end
        player.set_weapon(command[1])
      when "swarm"
        if Config.allowed(:cheats)
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
                entity = Entity.new("goblin", *npos.reverse)
              end
            end
          end
        else
          Console.not_allowed_message
        end
      when "cam"
        GameEngine.set_camera(*command[1..-1])
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
      end
    rescue Exception => e
      if Config.get(:debug_mode)
        puts "\"/#{command.join(" ")}\" threw exception: #{e.to_s}\n#{e.backtrace.join("\n")}"
      end
      Console.command_failed_message
    end
  end

  def self.get_command(player)
    string = Input.get_input
    return if string == :abort
    run(string.delete("/").chomp, player)
  end

  def self.not_allowed_message
    GameEngine.show_at_top("Cheats are not enabled")
  end

  def self.command_failed_message
    GameEngine.show_at_top("Improper command")
  end
end