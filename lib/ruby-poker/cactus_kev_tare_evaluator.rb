require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_five_card_evaluator_tables', __FILE__)

=begin rdoc
    CactusKevEvaluator (fast), using lookup tables and using a perfect hash to evaluate
    non-straight, non-flush hands.
=end
class CactusKevTareEvaluator < CactusKev::CactusKevValueEvaluator
    include CactusKev
    
    def score
        cactus_kev_hand_eval(@hand.to_a.map{|each| each.cactus_kev_card_value})
    end
    
private

    # pass card array to approrpiate evaluator based on hand size
    def cactus_kev_hand_eval(cards)
        integer_result = case cards.size
        when 5: eval_5_cards_fast(*cards)
        when 7: eval_7_card_hand(cards)
        else raise "This evaluator can only handle 5-card hands"
        end
        EqClTable[integer_result]
    end
    
    # evaluate using modified cactus_kev evaluator with perfect hash, returning an integer
    def eval_5_cards_fast( c1, c2, c3, c4, c5)
        1
    end

    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    def eval_7_card_hand( cards )
        1
    end
end