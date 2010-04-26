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
    # 
    # def score
    #     cards = @hand.to_a
    #     case cards.size
    #     when 5 then eval_5_card_hand(cards.to_a)
    #     when 6 then eval_bigger_hand(cards.to_a)
    #     when 7 then eval_bigger_hand(cards.to_a)
    #     else raise "This evaluator can only handle 5-card hands"
    #     end
    # end
    
    def score
        cards = @hand.to_a
        size = cards.size
        eq_cl_code = if size == 5
            eval_5_cards(*cards)
        elsif size == 7
            eval_n_cards_unrolled(cards, false) #optimized for 7 cards
        elsif size == 6
            eval_n_cards_unrolled(cards, true) #optimized for 6 cards
        elsif size > 5
            eval_n_cards(cards)
        else
            raise "not enough cards(#{size}) for evaluation"
        end
    end
    
private
    def eval_5_cards(c1, c2, c3, c4, c5)
        product = Card::Primes[c1.face-1] * Card::Primes[c2.face-1] * Card::Primes[c3.face-1] * 
                    Card::Primes[c4.face-1] * Card::Primes[c5.face-1]
        result = if (c1.suit == c2.suit) && (c2.suit==c3.suit) && (c3.suit==c4.suit) && (c4.suit==c5.suit)
            EqClNodeHash[product].eq_flush
        else
            EqClNodeHash[product].eq_nonflush
        end
        raise "unrecognized #{c1}#{c2}#{c3}#{c4}#{c5}" if result.nil?
        result
    end
    
    # special case unrolling eval_n_cards for 6 and 7 cards
    def eval_n_cards_unrolled(cards, has_6_cards)
    	best=eval_5_cards( cards[0], cards[1], cards[2], cards[3], cards[4] )
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[3], cards[5] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[4], cards[5] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[3], cards[4], cards[5] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[2], cards[3], cards[4], cards[5] )) > best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[2], cards[3], cards[4], cards[5] )) > best then best=q; end
    	return best if has_6_cards
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[3], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[4], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[3], cards[4], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[3], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[4], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[2], cards[3], cards[4], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[2], cards[3], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[2], cards[4], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[3], cards[4], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[2], cards[3], cards[4], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[2], cards[3], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[2], cards[4], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[3], cards[4], cards[5], cards[6] )) > best then best=q; end
    	if (q=eval_5_cards( cards[2], cards[3], cards[4], cards[5], cards[6] )) > best then best=q; end
    	best
    end
    
    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    def eval_n_cards_hand( cards )
        best = EqClTable.last
        cards.combination(5).each do |each_5_card_combination|
            best = [eval_5_cards(*each_5_card_combination), best].max
        end
        best
    end
end