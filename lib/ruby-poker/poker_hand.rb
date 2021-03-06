class PokerHand
  include Comparable
  attr_reader :hand
  
  @@allow_duplicates = true    # true by default
  def self.allow_duplicates; @@allow_duplicates; end
  def self.allow_duplicates=(v); @@allow_duplicates = v; end
  
  # Returns a new PokerHand object. Accepts the cards represented
  # in a string or an array
  #
  #     PokerHand.new("3d 5c 8h Ks")   # => #<PokerHand:0x5c673c ...
  #     PokerHand.new(["3d", "5c", "8h", "Ks"])  # => #<PokerHand:0x5c2d6c ...
  def initialize(cards = [], evaluator_klass=HurleyEvaluator)
    if cards.is_a? Array
      @hand = cards.map do |card|
        if card.is_a? Card
          card
        else
          Card.new(card.to_s)
        end
      end
    elsif cards.respond_to?(:to_str)
      @hand = cards.scan(/\S{2,3}/).map { |str| Card.new(str) }
    else
      @hand = cards
    end
    
    check_for_duplicates if !@@allow_duplicates
    @evaluator = evaluator_klass.new(self)
  end
  
  # Returns a new PokerHand object with the cards sorted by suit
  # The suit order is spades, hearts, diamonds, clubs
  #
  #     PokerHand.new("3d 5c 8h Ks").by_suit.just_cards   # => "Ks 8h 3d 5c"
  def by_suit
    PokerHand.new(@hand.sort_by { |c| [c.suit, c.face] }.reverse)
  end

  # Returns a new PokerHand object with the cards sorted by value
  # with the highest value first.
  #
  #     PokerHand.new("3d 5c 8h Ks").by_face.just_cards   # => "Ks 8h 5c 3d"
  def by_face
    PokerHand.new(@hand.sort_by { |c| [c.face, c.suit] }.reverse)
  end
  
  # Returns string representation of the hand without the rank
  #
  #     PokerHand.new(["3c", "Kh"]).just_cards     # => "3c Kh"
  def just_cards
    @hand.join(" ")
  end
  alias :cards :just_cards
  
  # Returns an array of the card values in the hand.
  # The values returned are 1 less than the value on the card.
  # For example: 2's will be shown as 1.
  #
  #     PokerHand.new(["3c", "Kh"]).face_values     # => [2, 12]
  def face_values
    @hand.map { |c| c.face }
  end

  # The =~ method does a regular expression match on the cards in this hand.
  # This can be useful for many purposes. A common use is the check if a card
  # exists in a hand.
  #
  #     PokerHand.new("3d 4d 5d") =~ /8h/           # => nil
  #     PokerHand.new("3d 4d 5d") =~ /4d/           # => #<MatchData:0x615e18>
  def =~ (re)
    re.match(just_cards)
  end

  def hand_rating
      @evaluator.hand_rating
  end

  alias :rank :hand_rating
  
  def score
      @evaluator.score
  end
  
  def royal_flush?
      @evaluator.royal_flush?
  end

  def straight_flush?
      @evaluator.straight_flush?
  end

  def four_of_a_kind?
      @evaluator.four_of_a_kind?
  end

  def full_house?
      @evaluator.full_house?
  end
  
  def flush?
      @evaluator.flush?
  end

  def straight?
      @evaluator.straight?
  end

  def three_of_a_kind?
      @evaluator.three_of_a_kind?
  end

  def two_pair?
      @evaluator.two_pair?
  end

  def pair?
      @evaluator.pair?
  end

  def highest_card?
      @evaluator.highest_card?
  end

  # Returns a string of the hand arranged based on its rank. Usually this will be the
  # same as by_face but there are some cases where it makes a difference.
  #
  #     ph = PokerHand.new("As 3s 5s 2s 4s")
  #     ph.sort_using_rank        # => "5s 4s 3s 2s As"
  #     ph.by_face.just_cards       # => "As 5s 4s 3s 2s"   
  def sort_using_rank
    score.arranged_hand
  end
  
  # Returns string with a listing of the cards in the hand followed by the hand's rank.
  #
  #     h = PokerHand.new("8c 8s")
  #     h.to_s                      # => "8c 8s (Pair)"
  def to_s
    just_cards + " (" + hand_rating + ")"
  end
  
  # Returns an array of `Card` objects that make up the `PokerHand`.
  def to_a
    @hand
  end
  
  alias :to_ary :to_a
  
  def <=> other_hand
    self.score <=> other_hand.score
  end
  
  # Add a card to the hand
  # 
  #     hand = PokerHand.new("5d")
  #     hand << "6s"          # => Add a six of spades to the hand by passing a string
  #     hand << ["7h", "8d"]  # => Add multiple cards to the hand using an array
  def << new_cards
    if new_cards.is_a?(Card) || new_cards.is_a?(String)
      new_cards = [new_cards]
    end
    
    new_cards.each do |nc|
      unless @@allow_duplicates
        raise "A card with the value #{nc} already exists in this hand. Set PokerHand.allow_duplicates to true if you want to be able to add a card more than once." if self =~ /#{nc}/
      end
      
      @hand << Card.new(nc)
    end
  end
  
  # Remove a card from the hand.
  #
  #     hand = PokerHand.new("5d Jd")
  #     hand.delete("Jd")           # => #<Card:0x5d0674 @value=23, @face=10, @suit=1>
  #     hand.just_cards             # => "5d"
  def delete card
    @hand.delete(Card.new(card))
  end
  
  # Same concept as Array#uniq
  def uniq
    PokerHand.new(@hand.uniq)
  end
  
  # Resolving methods are just passed directly down to the @hand array
  RESOLVING_METHODS = [:size, :+, :-]
  RESOLVING_METHODS.each do |method|
    class_eval %{
      def #{method}(*args, &block)
        @hand.#{method}(*args, &block)
      end
    }
  end
  
  private
  
  def check_for_duplicates
    if @hand.size != @hand.uniq.size && !@@allow_duplicates
      raise "Attempting to create a hand that contains duplicate cards. Set PokerHand.allow_duplicates to true if you do not want to ignore this error."
    end
  end
end