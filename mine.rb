# Copyright (C) 2018 Marcus Lundgren

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class MinesweeperView
  def initialize()
  end

  def print_board(board)
    col_count = board[0].length
    row_separator = "    " + "----" * col_count + "-"

    # Initial row with col number indicator
    column_numbers = " " * 4
    for c in 1..col_count do
      column_numbers += "#{c} ".rjust(4)
    end
    puts column_numbers

    row_counter = 1
    board.each do |row|
      puts row_separator
      line_number  = "#{row_counter} ".rjust(4)
      row_s = line_number
      row_s += "|"
      row.each do |square|
        row_s += " "
       
        # if square.is_mine
        #   row_s += "X"
        # else
        #   row_s += square.adjacency_number.to_s
        # end

        case square.current_state
        when Square::StateUntouched
          row_s += "_"
        when Square::StateSwept
          if square.is_mine
            row_s += "X"
          else
            adj_n = square.adjacency_number
            if adj_n > 0
              row_s += square.adjacency_number.to_s
            else
              row_s += " "
            end
          end
        when Square::StateFlagged
          row_s += "F"
        end
       
        row_s += " |"
      end
      row_s += line_number
      puts row_s
      row_counter += 1
    end
    puts row_separator
    puts column_numbers
  end

  def print_defeat()
    puts "You lost... Type <r width height mines> to try again"
  end

  def print_victory()
    puts "You WON! Type <r width height mines> to have another go"
  end
end

class MinesweeperController
  def initialize(view, model)
    @view = view
    @model = model
    @is_game_finished = false
  end

  def reset(width, height, mines)
    @is_game_finished = false
    @model.reset(width, height, mines)
    _refresh_view()
  end

  def sweep(x, y)
    @model.sweep(x - 1, y - 1)
    _refresh_view()

    if @model.is_mine(x -1, y - 1)
      @view.print_defeat()
    else
      _check_for_victory()
    end
  end

  def flag(x, y)
    @model.flag(x - 1, y - 1)
    _refresh_view()
  end

  def _check_for_victory
    unless @model.unswept_none_mines_left()
      @view.print_victory()
    end
  end

  def _refresh_view()
    system "clear" or system "cls"
    @view.print_board(@model.board)
  end
end

class Square
  StateUntouched = 0
  StateSwept = 1
  StateFlagged = 2

  attr_accessor :current_state
  attr_accessor :is_mine
  attr_accessor :adjacency_number

  def initialize(is_mine)
    @is_mine = is_mine
    @current_state = StateUntouched
    @adjacency_number = 0
  end

  def sweep()
    @current_state = StateSwept
  end

  def flag()
    case @current_state
    when Square::StateFlagged
      @current_state = Square::StateUntouched
    when Square::StateUntouched
      @current_state = Square::StateFlagged
    end
  end

  def increase_adjacency_number()
    if !@is_mine
      @adjacency_number += 1
    end
  end
end

class MinesweeperModel
  attr_accessor :board
 
  def initialize()
    @width = 0
    @height = 0
    @mines = 0
    @is_new_board = true
  end

  def reset(width, height, mines)
    @height = height
    @width = width
    @mines = mines
    @is_new_board = true
    @board = Array.new(height) { Array.new(width) { Square.new(false) } }
  end

  def unswept_none_mines_left()
    @board.each do |row|
      row.each do |square|
        if square.current_state == Square::StateUntouched and !square.is_mine
          return true
        end
      end
    end

    return false
  end

  def is_mine(x, y)
    square = get_square(x, y)
    unless square.nil?
      return square.is_mine
    end
   
    return false
  end

  def _place_mines(x, y)
    mines_placed = 0
    while mines_placed < @mines do
      random_col = rand(@width)
      random_row = rand(@height)

      if _is_adjacent(random_col, random_row, x, y)
        next
      end

      random_square = get_square(random_col, random_row)
      if !random_square.is_mine
        random_square.is_mine = true
        _increase_adjacency_numbers(random_col, random_row)
        mines_placed += 1
      end
    end
  end

  def _is_adjacent(x, y, orig_x, orig_y)
    return (orig_x - 1 <= x and x <= orig_x + 1 and
           orig_y - 1 <= y and y <= orig_y + 1)
  end

  def _increase_adjacency_numbers(x, y)
    # Top
    _increase_adjacency_number(x - 1, y - 1)
    _increase_adjacency_number(x    , y - 1)
    _increase_adjacency_number(x + 1, y - 1)
   
    # Sides
    _increase_adjacency_number(x - 1, y)
    _increase_adjacency_number(x + 1, y)
   
    # Bottom
    _increase_adjacency_number(x - 1, y + 1)
    _increase_adjacency_number(x    , y + 1)
    _increase_adjacency_number(x + 1, y + 1)
  end

  def _increase_adjacency_number(x, y)
    square = get_square(x, y)
    unless square.nil?
      square.increase_adjacency_number()
    end
  end

  def _sweep_adjacent_squares(x, y)
    # Top
    _sweep_adjacent_square(x - 1, y - 1)
    _sweep_adjacent_square(x    , y - 1)
    _sweep_adjacent_square(x + 1, y - 1)
   
    # Sides
    _sweep_adjacent_square(x - 1, y)
    _sweep_adjacent_square(x + 1, y)
   
    # Bottom
    _sweep_adjacent_square(x - 1, y + 1)
    _sweep_adjacent_square(x    , y + 1)
    _sweep_adjacent_square(x + 1, y + 1)
  end

  def _sweep_adjacent_square(x, y)
    square = get_square(x, y)
    unless square.nil?
      if square.current_state == Square::StateUntouched and !square.is_mine
        square.sweep()
        if square.adjacency_number == 0
          _sweep_adjacent_squares(x, y)
        end
      end
    end
  end

  def sweep(x, y)
    square = get_square(x, y)
    unless square.nil?
      if square.current_state == Square::StateUntouched
        if @is_new_board
          _place_mines(x, y)
          @is_new_board = false
        end

        square.sweep()
       
        if !square.is_mine and square.adjacency_number == 0
          _sweep_adjacent_squares(x, y)
        end
      elsif square.current_state == Square::StateSwept
        if _is_adjacent_flagged_squares_matching(x, y)
          _sweep_adjacent_squares(x, y)
        end
      end
    end
  end

  def _is_adjacent_flagged_squares_matching(x, y)
    count = 0
    # Top
    if _is_flagged(x - 1, y - 1)
      count += 1
    end
    if _is_flagged(x    , y - 1)
      count += 1
    end
    if _is_flagged(x + 1, y - 1)
      count += 1
    end
   
    # Sides
    if _is_flagged(x - 1, y)
      count += 1
    end
    if _is_flagged(x + 1, y)
      count += 1
    end
   
    # Bottom
    if _is_flagged(x - 1, y + 1)
      count += 1
    end
    if _is_flagged(x    , y + 1)
      count += 1
    end
    if _is_flagged(x + 1, y + 1)
      count += 1
    end

    square = get_square(x, y)
    return square.adjacency_number == count
  end

  def _is_flagged(x, y)
    square = get_square(x, y)
    unless square.nil?
      return square.current_state == Square::StateFlagged
    end
   
    return false
  end

  def flag(x, y)
    square = get_square(x, y)
    unless square.nil? or square.current_state == Square::StateSwept
      square.flag()
    end
  end

  def get_square(x, y)
    if 0 <= x and x < @width and
       0 <= y and y < @height
      return @board[y][x]
    end

    return nil
  end
end

class MinesweeperGame
  def initialize()
    model = MinesweeperModel.new()
    view = MinesweeperView.new()
    @controller = MinesweeperController.new(view, model)
  end

  def start()
    @controller.reset(10, 10, 10)
    input = ""

    while true do
      input = gets()
      split = input.split(" ")

      begin
        if split[0] == "s"
          @controller.sweep(Integer(split[1]), Integer(split[2]))
        elsif split[0] == "f"
          @controller.flag(Integer(split[1]), Integer(split[2]))
        elsif split[0] == "r"
          @controller.reset(Integer(split[1]), Integer(split[2]), Integer(split[3]))
        elsif split[0] == "x"
          return
        end
      rescue
        puts "Something went wrong. Check your previous command."
      end
    end
  end
end

game = MinesweeperGame.new()
game.start()
