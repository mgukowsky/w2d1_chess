require 'byebug'
require 'yaml'

class Tile
  attr_accessor :has_bomb, :flagged, :revealed

  def initialize()
  #  @board = board
    @has_bomb = false
    @flagged = false
    @revealed = false
  end

end

class Board
  DIRECTIONS = [[0, 1],
                [1, 1],
                [1, 0],
                [1, -1],
                [0, -1],
                [-1, -1],
                [-1, 0],
                [-1, 1]]

  attr_reader :tiles

  def one_dim
    @tiles.flatten
  end

  def initialize
    @tiles = []
    tile_row = []
    9.times do
      tile_row = []
      9.times do
        tile_row << Tile.new
      end
      @tiles << tile_row
    end
  end


  def [] (x,y)
    self.tiles[x][y]
  end

  def flagged(x, y)
    self[x, y].flagged = true
  end

  def revealed(x, y)
    self[x, y].revealed = true
  end

  def valid_coord(x)
    x.between?(0,8)
  end

  def seed_bombs
    bomb_count = 0
    #debugger
    while bomb_count < 10
      x = (0..8).to_a.shuffle[0]
      y = (0..8).to_a.shuffle[0]
      current_tile = self[x,y]
      unless current_tile.has_bomb
        current_tile.has_bomb = true
      #  @bomb_locations << [x, y]

        bomb_count += 1


      end
    end
  end

  def neighbor_bomb_count(x,y)
    neighbor_bombs = 0
    DIRECTIONS.each do |direction|
      x_diff, y_diff = direction

      next unless valid_coord(x+x_diff)
      next unless valid_coord(y+y_diff)
      neighbor = self[x+x_diff,y+y_diff]
      if neighbor.has_bomb
        neighbor_bombs += 1
      end
    end
    neighbor_bombs
  end

  def neighbor_reveal_count(x,y)
    neighbor_revealed = 0
    DIRECTIONS.each do |direction|
      x_diff, y_diff = direction
      next unless valid_coord(x+x_diff)
      next unless valid_coord(y+y_diff)
      neighbor = self[x+x_diff,y+y_diff]
      if neighbor.revealed
        neighbor_revealed += 1
      end
    end
    neighbor_revealed
  end
end


class Minesweeper

  DIRECTIONS = [[0, 1],
  [1, 1],
  [1, 0],
  [1, -1],
  [0, -1],
  [-1, -1],
  [-1, 0],
  [-1, 1]]

  attr_accessor :board

  def initialize
    @board = Board.new
    @done = false
    @won = false
    @save = false
    @flag_locations = []
  end

  def run(yaml = nil)
    puts "Welcome to Minesweeper"
    puts "Seeding bombs..."
    @board.seed_bombs

    unless yaml.nil?
      save_state = File.read(yaml)
      @board = YAML.load(save_state)
    end

    until @done
      display
      input = get_input
      update_board(input)

      if all_clear?
        @done = true
        @won = nil
      elsif all_flagged?
        puts "All bombs flagged, "
        @done = true
        @won = true
      end
    end
    if @save
      puts "Thanks for saving see you next time!"
      return nil
    end
    if @won
      puts "CONGRATULATIONS, YOU WIN!!!"
    else
      puts "you lose :("
    end
    nil
  end

  def display
    @board.tiles.each_with_index do |row, y|
      output_string = ""
      row.each_with_index do |tile, x|
          output_string += " #{get_symbol(x,y)}"
      end
      puts output_string.strip
    end
    puts
    nil

  end

  def get_input
    reprompt = false
    x, y, move_action = nil
    loop do
      puts "I didn't understand, please try again" if reprompt
      puts "What X coordinate do you want (0-8)?"
      x = gets.chomp
      x = x.to_i if x
      puts "What Y coordinate do you want (0-8)?"
      y = gets.chomp
      y = y.to_i if y
      puts "Enter R for reveal or F for flag.  Enter 'Save' to save the game"
      move_action = gets.chomp.upcase

      break if ((move_action == "R" ||
                 move_action == "F" ||
                 move_action == "SAVE") &&
                (x.between?(0, 8) && y.between?(0, 8)))
      reprompt = true
    end

    [x, y, move_action]
  end

  def update_board(input)
    x = input.shift
    y = input.shift
    action = input.shift
    if action == "Save"
      saved_game = @board.to_yaml
      File.open("saved_game.txt", "w") do |f|
        f.puts saved_game

      end
      p saved_game
      @done = true
      @save = true
    elsif action == 'R'
      if @board[x,y].has_bomb
        finish_game
        @done = true
        @won = false
      else
        recursive_reveal(x,y)
      end
    else
      @board.flagged(x, y)
      @flag_locations << [x, y]
    end
  end

  def finish_game
    tiles = @board.one_dim
    tiles.each do |tile|
      unless tile.revealed
          tile.revealed = true
      end
    end
    self.display
  end

  def recursive_reveal(x,y)
    # debugger

    if @board[x, y].revealed
      return nil
    end

    if @board.neighbor_bomb_count(x,y) > 0
      @board[x,y].revealed = true
      return nil
    end

    @board[x,y].revealed = true
    DIRECTIONS.each do |direction|
      x_diff, y_diff = direction
      next unless @board.valid_coord(x+x_diff)
      next unless @board.valid_coord(y+y_diff)

      recursive_reveal(x + x_diff, y + y_diff)
    end
    nil
  end

  def all_clear?
    tiles = @board.one_dim
    tiles.each do |tile|
      next if tile.flagged
      return false unless tile.revealed
    end
    true
  end

  def all_flagged?
    tiles = @board.one_dim
    correct_flags = 0
    tiles.each do |tile|
        correct_flags += 1 if tile.flagged && tile.has_bomb
    end
    if correct_flags >= 10
       true
    else
       false
    end
  end


  def get_symbol(x,y)
    temp_tile = @board[x,y]
    bomb_count = @board.neighbor_bomb_count(x,y)
    if temp_tile.revealed && temp_tile.has_bomb
      return "B"

    elsif bomb_count > 0 && @board[x,y].revealed

      return bomb_count.to_s

    elsif temp_tile.revealed
      return "_"

    elsif temp_tile.flagged
      return "F"


    else
      return "*"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  m = Minesweeper.new
  m.run
end
