module GameEngine
  @@cam_x = 0
  @@cam_y = 0
  @@menu_y = 0
  @@clearqueue = []
  @@board_margin_top = 1
  @@board_margin_bottom = 5
  @@top_text = ""
  @@rendered_menu_y = -1
  @@last_selected = []

  def self.calculate_corners
    @@board_left_wall =           1
    @@board_right_wall =          Curses.cols - 2
    @@board_top_wall =            @@board_margin_top + 1
    @@board_bottom_wall =         Curses.lines - @@board_margin_bottom - 2
    @@board_width =               @@board_right_wall - @@board_left_wall
    @@board_height =              @@board_bottom_wall - @@board_top_wall
    @@board_top_left =            [@@board_top_wall, @@board_left_wall]
    @@board_top_right =           [@@board_top_wall, @@board_right_wall]
    @@board_bottom_left =         [@@board_bottom_wall, @@board_left_wall]
    @@board_bottom_right =        [@@board_bottom_wall, @@board_right_wall]
    @@board_wall_top_left =       [@@board_top_wall - 1, 0]
    @@board_wall_bottom_left =    [@@board_bottom_wall + 1, 0]
    @@inv_top_left =              [@@board_bottom_wall + 2, Curses.cols / 3 * 2 + 1]
    @@inv_bot_right =             [Curses.lines - 2, Curses.cols - 2]
    @@menu_top_left =             [0, 2]
    @@menu_bottom_right =         [Curses.lines - 2, Curses.cols - 2]
    @@menu_height =               @@menu_bottom_right[0] - @@menu_top_left[0]
    @@weapon_display =            @@board_bottom_left.dup
    @@weapon_display[0] +=        2 
    @@weapon_display[1] +=        1
    @@hp_display =                @@weapon_display.dup
    @@hp_display[0] +=            1
    @@hp_display2 =               @@hp_display.dup
    @@hp_display2[0] +=           1
    @@health_bar_size =           Curses.cols / 3 - 2
    @@annoying_console_wall =     @@inv_bot_right.dup
    @@annoying_console_wall[1] += 1  
    @@horiz_margin =              @@board_width / 15 + 3
    @@verti_margin =              @@board_height / 10 + 2
    @@console_start =             [Curses.lines - 2, 1]
  end

  def self.rendered_menu_y=(val)
    @@rendered_menu_y = val
  end

  def self.render_corners
    GameEngine.calculate_corners
    [@@board_top_left, @@board_top_right, @@board_bottom_left, @@board_bottom_right].each do |pos|
      GameEngine.render_char_at(pos)
    end
  end

  def self.render_char_at(pos, char = ".")
    Curses.setpos(*pos)
    Curses.addstr(char)
  end

  def self.render_board_walls
    Curses.setpos(*@@board_wall_top_left)
    Curses.addstr("*" * Curses.cols)

    Curses.setpos(*@@board_wall_bottom_left)
    Curses.addstr("*" * Curses.cols)
    
    (@@board_top_wall..@@board_bottom_wall).each do |y|
      render_char_at([y, 0], "*")
      render_char_at([y, Curses.cols - 1], "*")
    end
  end

  def self.set_cursor_bottom_left
    Curses.setpos(*@@console_start)
  end
  
  def self.debug(text)
    return unless Config.get(:debug_mode)
    GameEngine.alert = text
    Curses.refresh
  end

  def self.show_at_top(text)
    Curses.setpos(0, 0)
    Curses.addstr(" " * Curses.cols)
    Curses.setpos(0, (Curses.cols - text.length) / 2)
    Curses.addstr(text.to_s)
  end

  def self.render_wall(wall)
    y1, x1 = tweak_pos_to_frame(wall.top_left)
    y2, x2 = tweak_pos_to_frame(wall.bot_right)
    
    if @@board_left_wall > x1 # board edge seinän keskellä x4
      x1 = @@board_left_wall
    end
    if @@board_right_wall < x2
      x2 = @@board_right_wall
    end
    if @@board_top_wall > y1
      y1 = @@board_top_wall
    end
    if @@board_bottom_wall < y2
      y2 = @@board_bottom_wall
    end

    if x2 < x1 || y2 < y1
      return # room not in frame
    end

    string = wall.material * (x2 - x1 + 1)
    
    (y1..y2).each do |y|
      Curses.setpos(y, x1)
      Curses.addstr(string)
    end
  end

  def self.room_in_frame(room)
    y1, x1 = tweak_pos_to_frame(room.top_left)
    y2, x2 = tweak_pos_to_frame(room.bot_right)

    if @@board_left_wall > x1 # board edge seinän keskellä x4
      x1 = @@board_left_wall
    end
    if @@board_right_wall < x2
      x2 = @@board_right_wall
    end
    return false if x2 < x1

    if @@board_top_wall > y1
      y1 = @@board_top_wall
    end
    if @@board_bottom_wall < y2
      y2 = @@board_bottom_wall
    end
    return false if y2 < y1

    true
  end

  def self.render_room(room)
    if room_in_frame(room)
      room.walls.each do |wall|
        render_wall(wall)
      end
    end
  end

  def self.render_player_stuff(player)
    clear_player_box

    #weapon
    wtxt = case player.weapon
    when nil then "Weapon: none"
    else
      player.weapon.weapontxt(@@health_bar_size)
    end
    Curses.setpos(*@@weapon_display)
    Curses.addstr(wtxt)

    #hp
    Curses.setpos(*@@hp_display)
    Curses.addstr(player.hp_display(@@health_bar_size))

    #latest enemy hp
    unless player.last_enemy.nil?
      Curses.setpos(*@@hp_display2)
      Curses.addstr(player.last_enemy.hp_display(@@health_bar_size))
    end
  
    #inv
    render_array_in_area(player.inventory_text, @@inv_top_left, @@inv_bot_right)

    #top text, not really player stuff but ehh...
    if !@@top_text.nil?
      show_at_top(@@top_text)
    end
  end

  def self.alert=(text)
    @@top_text = text
    show_at_top(@@top_text)
  end

  def self.camera_pos
    return [@@cam_y, @@cam_x]
  end

  def self.move_cam_if_necessary(pos)
    y, x = tweak_pos_to_frame(pos)
    camy = @@cam_y 
    camx = @@cam_x

    while @@board_top_wall + @@verti_margin > y
      camy -= @@verti_margin
      y += @@verti_margin # the while loop doesn't know the camera moved, this is so it knows
    end
    while @@board_bottom_wall - @@verti_margin < y
      camy += @@verti_margin
      y -= @@verti_margin
    end
    while @@board_left_wall + @@horiz_margin > x
      camx -= @@horiz_margin
      x += @@horiz_margin
    end
    while @@board_right_wall - @@horiz_margin < x
      camx += @@horiz_margin
      x -= @@horiz_margin
    end
    
    if camx != @@cam_x || camy != @@cam_y
      set_camera(camy, camx)
    end
  end

  def self.clear_player_box
    ((@@board_bottom_wall + 2)...(Curses.lines - 1)).each do |y|
      Curses.setpos(y, 1)
      Curses.addstr(" " * (Curses.cols - 2))
    end
  end

  def self.in_frame(y, x)
    return @@board_left_wall <= x && @@board_right_wall >= x && @@board_top_wall <= y && @@board_bottom_wall >= y
  end

  def self.tweak_pos_to_frame(pos)
    return MathHelpers.arrsub(pos, [@@cam_y, @@cam_x])
  end

  def self.render_entities
    Entity.old_entities.each do |pos|
      pos = tweak_pos_to_frame(pos)
      if in_frame(*pos)
        GameEngine.render_char_at(pos, " ")
      end
    end
    Entity.clear_old_entities # clear @@old_entities
    
    already_rendered = Set.new
    priorities = Hash.new
    Entity.entities.each do |entity|
      pos = tweak_pos_to_frame(entity.pos)
      if in_frame(*pos) && !Room.walls_collide(*entity.pos)
        if already_rendered.include?(pos)
          if entity.render_priority > priorities[pos]
            render_char_at(pos, entity.char)
            priorities[pos] = entity.render_priority
          end
        else
          render_char_at(pos, entity.char)
          already_rendered << pos
          priorities[pos] = entity.render_priority
        end
      end
    end

    render_char_at(tweak_pos_to_frame(Entity.player.pos), Entity.player.char)
  end

  def self.render_console_right_wall
    render_char_at(@@annoying_console_wall, "*")
  end

  def self.flash
    GameTime.while_paused do
      Curses.flash
    end
  end

  def self.init
    Curses.init_screen
    Curses.start_color
    Curses.stdscr.keypad(true)
    Curses.cbreak
    Curses.noecho
    GameEngine.calculate_corners
    Curses.curs_set(0)
  end

  def self.clear
    Curses.clear
    render_board_walls
    render_bottom_dividers
    render_rooms
  end

  def self.render_array_in_area(arr, pos, pos2, *flags)
    y1, x1 = pos
    y2, x2 = pos2
    if y1 > y2
      y2, y1 = y1, y2
    end
    if x1 > x2
      x2, x1 = x1, x2
    end
    cy, cx = pos
    crowsize = 0
    rowsize = (x1 - x2).abs
    Curses.setpos(cy, cx)
    arr.each do |cur|
      crowsize += cur.length + 1
      if crowsize <= rowsize && !flags.include?(:force_newline)
        Curses.addstr(cur.to_s)
        if crowsize != rowsize
          Curses.addstr(" ")
        end
      else
        cy += 1
        cx = x1
        crowsize = 0
        crowsize += cur.length + 1
        if flags.include?(:align_right)
          cx = Curses.cols - crowsize
        end    
        if crowsize >= rowsize
          puts("failure while rendering array")
          return
        end
        return if cy > y2
        Curses.setpos(cy, cx)
        Curses.addstr(cur.to_s)
        if crowsize != rowsize
          Curses.addstr(" ")
        end
      end
    end
  end

  def self.render_rooms
    Room.rooms.each do |room|
      if room_in_frame(room)
        render_room(room)
      end
    end
  end
  
  def self.clear_game_box
    erow = " " * (@@board_right_wall - @@board_left_wall)
    (@@board_top_wall..@@board_bottom_wall).each do |y|
      Curses.setpos(y, @@board_left_wall)
      Curses.addstr(erow)
    end
  end

  def self.set_camera(y, x)
    clear_game_box
    @@cam_y = y.to_i
    @@cam_x = x.to_i
    render_rooms
  end

  def self.clear_queue
    @@clearqueue.each do |y, x|
      Curses.setpos(y, x)
      GameEngine.render_char_at([y, x], " ")
    end
    @@clearqueue = []
  end
  
  def self.render_selected(selected)
    y, x = @@menu_top_left
    y += selected
    x -= 1
    render_char_at([y, x], ">")
    @@clearqueue << [y, x]
  end

  def self.render_bottom_dividers
    ((@@board_bottom_wall+2)...(Curses.lines - 1)).each do |y|
      GameEngine.render_char_at([y, 0], "*")
      GameEngine.render_char_at([y, Curses.cols - 1], "*")
    end
    Curses.setpos(Curses.lines - 1, 0)
    Curses.addstr("*" * Curses.cols)
  end

  def self.render
    render_entities
    render_player_stuff(Entity.player)

    GameEngine.set_cursor_bottom_left
    Curses.refresh  
  end

  def self.menu_y=(value)
    @@menu_y = value
  end

  def self.move_menu(dir, menu_size)
    return if menu_size < @@menu_height # never move menu if it fits on screen
    @@menu_y += dir
    if @@menu_y < 0
      @@menu_y = 0
    elsif @@menu_y + @@menu_height > menu_size
      @@menu_y = menu_size - @@menu_height
    end
    Curses.clear
  end

  def self.render_menu(menu, selected = nil, first_option = nil, **flags)
    clear_queue
    #Curses.clear # TODO: add right menu elements to clear_queue for optimization
    if @@menu_y != @@rendered_menu_y    
      render_array_in_area(menu[@@menu_y..(@@menu_y + @@menu_height)], @@menu_top_left, @@menu_bottom_right, :force_newline)
      @@rendered_menu_y = @@menu_y
    end
    
    unless selected.nil?
      if selected <= @@menu_y
        @@menu_y = selected - 2
        if @@menu_y < 0
          @@menu_y = 0
        end
        if @@menu_y < first_option
          @@menu_y = 0
        end
      elsif selected > @@menu_y + @@menu_height
        @@menu_y = selected - @@menu_height
      end
      render_selected(selected - @@menu_y)
      if flags[:show_stats]
        render_array_in_area(@@last_selected.map { |str| " " * str.length }, @@menu_top_left, @@menu_bottom_right, :force_newline, :align_right)
        render_array_in_area(menu[selected - 1].stats_array, @@menu_top_left, @@menu_bottom_right, :force_newline, :align_right)
        @@last_selected = menu[selected - 1].stats_array
      end
    end

    GameEngine.render_char_at(@@console_start, " ")
    set_cursor_bottom_left

    Curses.refresh
  end
end
