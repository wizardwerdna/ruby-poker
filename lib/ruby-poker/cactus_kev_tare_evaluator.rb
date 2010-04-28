require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_five_card_evaluator_tables', __FILE__)

=begin rdoc
    CactusKevEvaluator (fast), using lookup tables and using a perfect hash to evaluate
    non-straight, non-flush hands.
=end
class CactusKevTareEvaluator < CactusKev::CactusKevValueEvaluator
    include CactusKev
    
    def score
        cards = @hand.to_a.map{|each| each.cactus_kev_card_value}
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
        EqClTable[eq_cl_code]
    end
    
private
    
    # evaluate using modified cactus_kev evaluator with perfect hash, returning an integer
    def eval_5_cards( c1, c2, c3, c4, c5)
        1
    end

    # evaluate each combination using eval_5cards_fast, returning the best result as an integer
    def eval_7_card_hand( cards )
        1
    end
    
    # return the integer corresponding to the best score of all 5-card combinations from cards
    def eval_n_cards(cards)
        cards.combination(5).inject(EqClTable.last.code) do |best_code, comb|
            q=eval_5_cards(*comb)
            if q<best_code then q; else best_code; end
        end
    end

    # special case unrolling eval_n_cards for 6 and 7 cards
    def eval_n_cards_unrolled(cards, has_6_cards=false)
    	best=eval_5_cards( cards[0], cards[1], cards[2], cards[3], cards[4] )
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[3], cards[5] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[4], cards[5] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[3], cards[4], cards[5] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[2], cards[3], cards[4], cards[5] )) < best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[2], cards[3], cards[4], cards[5] )) < best then best=q; end
    	return best if has_6_cards
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[3], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[4], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[2], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[3], cards[4], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[3], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[1], cards[4], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[2], cards[3], cards[4], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[2], cards[3], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[2], cards[4], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[0], cards[3], cards[4], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[2], cards[3], cards[4], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[2], cards[3], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[2], cards[4], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[1], cards[3], cards[4], cards[5], cards[6] )) < best then best=q; end
    	if (q=eval_5_cards( cards[2], cards[3], cards[4], cards[5], cards[6] )) < best then best=q; end
    	best
	end
end