class Input

  def self.get_input(string = "")
    GameEngine.render_console_right_wall
    GameEngine.set_cursor_bottom_left
    char = ""

    while char != 10 # 10 = enter
      if char == 8 # 8 = backspace
        if string.length > 0
          string = string[0...-1]
          Curses.addstr("  ")
        end
      elsif char == 3 || char == 27 # ctrlc, esc
        return :abort
      elsif char.class == String
        string += char
      else
        string += ".." # korjaa combo desyncit (^T) (..)
      end
      Curses.setpos(Curses.lines - 2, string.length + 1)
      Curses.refresh
      char = Curses.getch
    end
    GameEngine.render_console_right_wall # need to fix the wall that has disappeared: \n gets echoed....
    return string
  end
end