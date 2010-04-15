require File.expand_path('../naive_value', __FILE__)

class NaiveTareEvaluator
    include Naive
    
    def initialize(hand)
        @hand = hand
    end

    OPS = [
      ['Royal Flush',     :royal_flush? ],
      ['Straight Flush',  :straight_flush? ],
      ['Four of a kind',  :four_of_a_kind? ],
      ['Full house',      :full_house? ],
      ['Flush',           :flush? ],
      ['Straight',        :straight? ],
      ['Three of a kind', :three_of_a_kind?],
      ['Two pair',        :two_pair? ],
      ['Pair',            :pair? ],
      ['Highest Card',    :highest_card? ],
    ]
    
    def score
        # OPS.map returns an array containing the result of calling each OPS method again
        # the poker hand. The non-nil cell closest to the front of the array represents
        # the highest ranking.
        # find([0]) returns [0] instead of nil if the hand does not match any of the rankings
        # which is not likely to occur since every hand should at least have a highest card
        NaiveScore.new [[1, 2], 3]
    end
    
    # Returns the verbose hand rating
    #
    #     PokerHand.new("4s 5h 6c 7d 8s").hand_rating     # => "Straight"
    def hand_rating
        "Royal Flush"
    end

	def royal_flush?
        if (md = (@hand.by_suit =~ /A(.) K\1 Q\1 J\1 T\1/))
          NaiveScore.new [[10], arrange_hand(md)]
        else
          false
        end
	end

	def straight_flush?
        if (md = (/.(.)(.)(?: 1.\2){4}/.match(delta_transform(true))))
          high_card = Card::face_value(md[1])
          arranged_hand = fix_low_ace_display(md[0] + ' ' +
              md.pre_match + ' ' + md.post_match)
          NaiveScore.new [[9, high_card], arranged_hand]
        else
          false
        end
	end

	def four_of_a_kind?
        if (md = (@hand.by_face =~ /(.). \1. \1. \1./))
          # get kicker
          (md.pre_match + md.post_match).match(/(\S)/)
          NaiveScore.new [
            [8, Card::face_value(md[1]), Card::face_value($1)],
            arrange_hand(md)
          ]
        else
          false
        end
	end

	def full_house?
        if (md = (@hand.by_face =~ /(.). \1. \1. (.*)(.). \3./))
          arranged_hand = arrange_hand(md[0] + ' ' +
              md.pre_match + ' ' + md[2] + ' ' + md.post_match)
          NaiveScore.new [
            [7, Card::face_value(md[1]), Card::face_value(md[3])],
            arranged_hand
          ]
        elsif (md = (@hand.by_face =~ /((.). \2.) (.*)((.). \5. \5.)/))
          arranged_hand = arrange_hand(md[4] + ' '  + md[1] + ' ' +
              md.pre_match + ' ' + md[3] + ' ' + md.post_match)
          NaiveScore.new [
            [7, Card::face_value(md[5]), Card::face_value(md[2])],
            arranged_hand
          ]
        else
          false
        end
	end

	def flush?
        if (md = (@hand.by_suit =~ /(.)(.) (.)\2 (.)\2 (.)\2 (.)\2/))
          NaiveScore.new [
            [
              6,
              Card::face_value(md[1]),
              *(md[3..6].map { |f| Card::face_value(f) })
            ],
            arrange_hand(md)
          ]
        else
          false
        end
	end

	def straight?
        result = false
        if @hand.hand.size >= 5
          transform = delta_transform
          # note we can have more than one delta 0 that we
          # need to shuffle to the back of the hand
          i = 0
          until transform.match(/^\S{3}( [1-9x]\S\S)+( 0\S\S)*$/) or i >= @hand.hand.size  do
            # only do this once per card in the hand to avoid entering an
            # infinite loop if all of the cards in the hand are the same
            transform.gsub!(/(\s0\S\S)(.*)/, "\\2\\1")    # moves the front card to the back of the string
            i += 1
          end
          if (md = (/.(.). 1.. 1.. 1.. 1../.match(transform)))
            high_card = Card::face_value(md[1])
            arranged_hand = fix_low_ace_display(md[0] + ' ' + md.pre_match + ' ' + md.post_match)
            result = NaiveScore.new [[5, high_card], arranged_hand]
          end
        end
        result
	end

	def three_of_a_kind?
        if (md = (@hand.by_face =~ /(.). \1. \1./))
          # get kicker
          arranged_hand = arrange_hand(md)
          arranged_hand.match(/(?:\S\S ){3}(\S)\S (\S)/)
          NaiveScore.new [
            [
              4,
              Card::face_value(md[1]),
              Card::face_value($1),
              Card::face_value($2)
            ],
            arranged_hand
          ]
        else
          false
        end
	end

	def two_pair?
    # \1 is the face value of the first pair
    # \2 is the card in between the first pair and the second pair
    # \3 is the face value of the second pair
        if (md = (@hand.by_face =~ /(.). \1.(.*?) (.). \3./))
          # to get the kicker this does the following
          # md[0] is the regex matched above which includes the first pair and
          # the second pair but also some cards in the middle so we sub them out
          # then we add on the cards that came before the first pair, the cards
          # that were in-between, and the cards that came after.
          arranged_hand = arrange_hand(md[0].sub(md[2], '') + ' ' +
              md.pre_match + ' ' + md[2] + ' ' + md.post_match)
          arranged_hand.match(/(?:\S\S ){4}(\S)/)
          NaiveScore.new [
            [
              3,
              Card::face_value(md[1]),    # face value of the first pair
              Card::face_value(md[3]),    # face value of the second pair
              Card::face_value($1)        # face value of the kicker
            ],
            arranged_hand
          ]
        else
          false
        end
	end

	def pair?
        if (md = (@hand.by_face =~ /(.). \1./))
          # get kicker
          arranged_hand = arrange_hand(md)
          arranged_hand.match(/(?:\S\S ){2}(\S)\S\s+(\S)\S\s+(\S)/)
          NaiveScore.new [
            [
              2,
              Card::face_value(md[1]),
              Card::face_value($1),
              Card::face_value($2),
              Card::face_value($3)
            ],
            arranged_hand
          ]
        else
          false
        end
	end

	def highest_card?
        result = @hand.by_face
        NaiveScore.new [[1, *result.face_values[0..4]], result.hand.join(' ')]
	end

	private

	# if md is a string, arrange_hand will remove extra white space
	# if md is a MatchData, arrange_hand returns the matched segment
	# followed by the pre_match and the post_match
	def arrange_hand(md)
      hand = if (md.respond_to?(:to_str))
        md
      else
        md[0] + ' ' + md.pre_match + md.post_match
      end
      hand.strip.squeeze(" ")   # remove extra whitespace
	end

	# delta transform creates a version of the cards where the delta
	# between card values is in the string, so a regexp can then match a
	# straight and/or straight flush
	def delta_transform(use_suit = false)
        aces = @hand.hand.select { |c| c.face == Card::face_value('A') }
        aces.map! { |c| Card.new(1,c.suit) }

        base = if (use_suit)
          (@hand + aces).sort_by { |c| [c.suit, c.face] }.reverse
        else
          (@hand + aces).sort_by { |c| [c.face, c.suit] }.reverse
        end

        result = base.inject(['',nil]) do |(delta_hand, prev_card), card|
          if (prev_card)
            delta = prev_card - card.face
          else
            delta = 0
          end
          # does not really matter for my needs
          delta = 'x' if (delta > 9 || delta < 0)
          delta_hand += delta.to_s + card.to_s + ' '
          [delta_hand, card.face]
        end

        # we just want the delta transform, not the last cards face too
        result[0].chop
	end

	def fix_low_ace_display(arranged_hand)
        # remove card deltas (this routine is only used for straights)
        arranged_hand.gsub!(/\S(\S\S)\s*/, "\\1 ")

        # Fix "low aces"
        arranged_hand.gsub!(/L(\S)/, "A\\1")

        # Remove duplicate aces (this will not work if you have
        # multiple decks or wild cards)
        arranged_hand.gsub!(/((A\S).*)\2/, "\\1")

        # cleanup white space
        arranged_hand.gsub!(/\s+/, ' ')
        # careful to use gsub as gsub! can return nil here
        arranged_hand.gsub(/\s+$/, '')
	end

end