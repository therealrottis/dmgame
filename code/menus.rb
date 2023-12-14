module Menus
  def self.menu(menu_name, selected = 0)
    Curses.clear
    GameEngine.menu_y = 0
    menu, props = Reader.read(menu_name)
    ogmenu = menu
    if menu_name == "menu"
      menu << ""
      menu << "version " + Config.version
      val2 = props[:options]
      val1 = val2 - 1
    elsif menu_name == "config"
      displayrows, settings_rows = Reader.read_config(menu_name)
      menu += displayrows
      props[:settings_rows] = settings_rows
      val2 = props[:options] + settings_rows.length
      val1 = val2 - 1
    elsif menu_name == "weapon_select"
      props[:weapons] = Entity.player.inventory.items
      menu += props[:weapons]
      val2 = Entity.player.inventory.length
      return if val2 <= 0
      val1 = val2 - 1
    else
      val2 = props[:options]
      val1 = val2 - 1
    end
    input = ""
    while input != 3
      GameEngine.render_menu(menu, selected * props[:optiongap] + props[:optionstart], props[:optionstart])
      input = Curses.getch

      if input == Curses::KEY_DOWN || input == Config.get(:key_down)
        selected += 1
      elsif input == Curses::KEY_UP || input == Config.get(:key_up)
        selected -= 1
      elsif input == 10
        yield props, selected

        if props[:rerender] # get value from other side of yield
          props[:rerender] = false
          menu = ogmenu + Reader.config_displayrows_from_rows(props[:settings_rows])
          val2 = props[:options] + props[:settings_rows].length
          val1 = val2 - 1
          Curses.clear
        end
      end

      if selected < 0 || selected > val1
        selected = ((selected + val2) % val2)
      end
    end
    exit # never used?
  end

  def self.visual_menu(menu_name)
    Curses.clear
    GameEngine.menu_y = 0
    menu, props = Reader.read(menu_name)
    if props[:need_subst]
      menu = Converter.substitute(menu, props)
    end
    input = ""
    while input != 3
      GameEngine.render_menu(menu)
      input = Curses.getch

      if input == Curses::KEY_DOWN || input == Config.get(:key_down)
        GameEngine.move_menu(1, menu.length)
      elsif input == Curses::KEY_UP || input == Config.get(:key_up)
        GameEngine.move_menu(-1, menu.length)
      elsif input == 10
        return
      end
    end
  end

  def self.main_menu(last_selected)
    menu("main_menu", last_selected) do |props, selected|
      return props[:optiontexts][selected]
    end
  end

  def self.about
    visual_menu("about")
    return
  end

  def self.settings
    menu("config") do |props, selected|
      if selected < props[:options]
        case props[:optiontexts][selected]
        when "settings_save_exit" 
          Config.save_config(props[:settings_rows])
          Config.load_config
          return
        when "settings_exit"
          return
        when "settings_add_setting"
          GameEngine.show_at_top("Name of new setting? ")
          string = Input.get_input
          GameEngine.show_at_top(" " * Curses.cols)
          if string.length != 0
            props[:settings_rows] << [string, " "]
          end
          props[:rerender] = true
        when "settings_remove_setting"
          GameEngine.show_at_top("Setting to remove? ")
          string = Input.get_input
          GameEngine.show_at_top(" " * Curses.cols)
          if string.length != 0
            props[:settings_rows].each_with_index do |pair, ind|
              key = pair[0]
              if key == string
                props[:settings_rows].delete_at(ind)
                break
              end
            end
          end
          props[:rerender] = true
        end
      else
        GameEngine.show_at_top("What do you want to change this to? ")
        string = Input.get_input
        GameEngine.show_at_top(" " * Curses.cols)
        props[:settings_rows][selected - props[:options]][1] = string
        props[:rerender] = true
      end
    end
  end

  def self.weapon_menu
    menu("weapon_select") do |props, selected|
      return props[:weapons][selected]
    end
  end
end