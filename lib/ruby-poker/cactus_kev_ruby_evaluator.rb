require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_five_card_evaluator_tables', __FILE__)

=begin rdoc
    CactusKevRubyEvaluator (original), using a direct ruby hash from the product of prime numbers
    corresponding to each card.  Because so much of the heavy lifting is passed to the machine
    language in the interpreter, I thought this would be a huge win, but despite its simplicity,
    it is a fair bit slower than the perfect hash cactus kev solution.
=end
class CactusKevRubyEvaluator < CactusKev::CactusKevValueEvaluator
    include CactusKev
    
    def score
        cards = @hand.to_a
        case cards.size
        when 5: eval_5_card_hand(cards.to_a)
        when 7: eval_7_card_hand(cards.to_a)
        else raise "This evaluator can only handle 5-card hands"
        end
    end
    
private

    def eval_5_card_hand(cards)
        product = 1
        cards_first_suit = cards.first.suit
        all_cards_same_suit = true
        cards.each do |card|
            product *= Card::Primes[card.face-1]
            all_cards_same_suit &= (card.suit==cards_first_suit)
        end
        if all_cards_same_suit
            EqClNodeHash[product].eq_flush
        else
            EqClNodeHash[product].eq_nonflush
        end
    end
    
    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    def eval_7_card_hand( cards )
        best = EqClTable.last
        Perm7.each do |perm|
            q = eval_5_card_hand(perm.map{|each| cards[each]})
            if q>best
                best = q
            end
        end
        best
    end
end