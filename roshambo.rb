module GameHands
  # Example of a more complicated game
  # BEATEN_BY = {
  #   rock: [:paper, :spock],
  #   paper: [:scissors, :lizard],
  #   scissors: [:rock, :spock],
  #   lizard: [:rock, :scissors],
  #   spock: [:paper, :lizard]
  # }.freeze

  BEATEN_BY = {
    rock: [:paper],
    paper: [:scissors],
    scissors: [:rock]
  }.freeze

  HANDS = BEATEN_BY.keys.freeze

  def get_outcome(player_hand, computer_hand)
    return :player if BEATEN_BY[computer_hand].include? player_hand
    return :computer if BEATEN_BY[player_hand].include? computer_hand
    :draw
  end
end

class WeightedRandom
  def initialize
    @rand = Random.new
  end

  def get_weighted_choice(choice_hash)
    sum_of_weights = Float(choice_hash.values.sum)
    rand_target = @rand.rand(sum_of_weights)
    choice_hash.each do |choice, weight|
      return choice if weight > rand_target

      rand_target -= weight
    end
  end

  def get_unweighted_choice(choice_list)
    choice_list.sample
  end
end

class Decision
  include GameHands
  def initialize
    @tracker_hash = {}
    @weighted_choice = WeightedRandom.new
    @state = %i[NULL N]
  end

  def update(new_state, player_choice)
    if @state != %i[NULL N]
      @tracker_hash[@state] ||= {}
      BEATEN_BY.each_key { |hand| @tracker_hash[@state][hand] ||= 0 }
      @tracker_hash[@state][player_choice] += 1
    end
    @state = new_state
  end

  def choice
    return @weighted_choice.get_unweighted_choice(HANDS) if @state == %i[NULL N] || !@tracker_hash.key?(@state)

    player_choice_guess = @weighted_choice.get_weighted_choice(@tracker_hash[@state])
    BEATEN_BY[player_choice_guess].sample
  end

  def print_tracker_hash
    @tracker_hash.each { |k, v| puts "#{k} => #{v}" }
  end
end

class Game
  include GameHands

  attr_accessor :score

  @@outcome_messages = {
    player: "You Win!",
    computer: "Computer Wins",
    draw: "It's a draw!"
  }

  def initialize(choice_maker)
    @score = {
      player: 0,
      computer: 0,
      draw: 0
    }
    @choice_maker = choice_maker
  end

  def throw
    comp_choice = @choice_maker.choice
    hands = HANDS.map { |hand| hand.to_s.capitalize }
    puts "Choose #{hands.join(', ')}, or Exit: "
    player_choice = yield

    return false if player_choice == :exit

    if player_choice == :print
      @choice_maker.print_tracker_hash
    elsif !HANDS.include? player_choice
      puts "Please choose a valid option."
    else
      result = get_outcome(player_choice, comp_choice)
      @choice_maker.update([player_choice, result], player_choice)
      @score[result] += 1
      puts "You chose: #{player_choice.capitalize}, Computer chose: #{comp_choice.capitalize}."
      puts @@outcome_messages[result]
      puts 'Current score:'
      puts "Player: #{@score[:player]}, Computer: #{@score[:computer]}, Draws: #{@score[:draw]}"
    end

    true
  end
end

class GameTypes
  include GameHands

  def initialize
    @game = Game.new(Decision.new)
  end

  def player_game
    while(@game.throw { gets.chomp.downcase.to_sym })
    end
  end

  def random_game(times_to_play)
    times_to_play.times { @game.throw { HANDS.sample } }
    @game.throw { :print }
  end

  def ordered_throw_game(times_to_play)
    0.upto(times_to_play) { |i| @game.throw { HANDS[i % HANDS.size] } }
    @game.throw { :print }
  end
end

def main
  games = GameTypes.new
  command_args = ARGV
  if ARGV.empty?
    games.player_game
  elsif command_args[0].downcase == "random"
    command_args.size > 1 ? games.random_game(command_args[1]) : games.random_game(1000)
  elsif command_args[0].downcase == "ordered"
    command_args.size > 1 ? games.ordered_throw_game(command_args[1]) : games.ordered_throw_game(1000)
  elsif command_args[0].downcase == "player"
    games.player_game
  elsif command_args[0].downcase == "help"
    puts 'Valid inputs are:'
    puts 'help - lists valid inputs.'
    puts 'random [<number>] - plays a game with random player choices with <number> hands (default 1000).'
    puts 'ordered [<number>] - plays a game with ordered player choices with <number> hands (default 1000).'
    puts 'player - plays a game with player input for hand choice. Runs until exit. No input will also run this version.'
  else
    puts 'Invalid input. Use input argument "help" for list of valid inputs.'
  end
end

main
