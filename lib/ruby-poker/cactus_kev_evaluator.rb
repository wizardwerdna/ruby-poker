require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_five_card_evaluator_tables', __FILE__)

=begin rdoc
    CactusKevEvaluator (fast), using lookup tables and using a perfect hash to evaluate
    non-straight, non-flush hands.
=end
class CactusKevEvaluator < CactusKev::CactusKevValueEvaluator
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
        q = (c1 | c2 | c3 | c4 | c5) >> 16;
        case
        when (c1 & c2 & c3 & c4 & c5 & 0xf000) > 0
            Flushes[q]
        when (s = Unique5[q]) > 0
            s
        else
            q = (c1&0xFF) * (c2&0xFF) * (c3&0xFF) * (c4&0xFF) * (c5&0xFF)
            q = find_perfect_hash( q )
            Hash_values[q]
        end
    end

    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    def eval_7_card_hand( cards )
        best = 9999
        Perm7.each do |perm|
            q = eval_5_cards_fast(
                cards[perm[0]], cards[perm[1]], cards[perm[2]], cards[perm[3]], cards[perm[4]])
            if q<best
                best = q
            end
        end
        best
    end
    
    # determine the index in Hash_values for this hand using perfect hash
    def find_perfect_hash(u)
        u = (u+0xe91aaa35) & 0xffffffff
        u ^= u >> 16;
        u = (u + (u << 8)) & 0xffffffff
        u ^= u >> 4;
        b  = (u >> 8) & 0x1ff;
        a  = ((u + (u << 2))&0xffffffff) >> 19;
        a ^ Hash_adjust[b];
    end
end