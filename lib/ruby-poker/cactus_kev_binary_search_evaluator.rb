require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_five_card_evaluator_tables', __FILE__)

=begin rdoc
    CactusKevEvaluator (original), using lookup tables and using a binary search to evaluate
    non-straight, non-flush hands.
=end
class CactusKevBinarySearchEvaluator < CactusKev::CactusKevValueEvaluator
    include CactusKev
    
    def score
        cactus_kev_hand_eval(@hand.to_a.map{|each| each.cactus_kev_card_value})
    end
    
private

    # pass card array to approrpiate evaluator based on hand size
    def cactus_kev_hand_eval(cards)
        integer_result = case cards.size
        when 5: eval_5_cards(*cards)
        when 7: eval_7_card_hand(cards)
        else raise "This evaluator can only handle 5-card hands"
        end
        EqClTable[integer_result]
    end

    
    def eval_5_cards( c1, c2, c3, c4, c5 )
        q = (c1|c2|c3|c4|c5) >> 16;
        case
        when (c1 & c2 & c3 & c4 & c5 & 0xF000)>0
            Flushes[q]
        when (s = Unique5[q])>0
            s
        else
            q = (c1&0xFF) * (c2&0xFF) * (c3&0xFF) * (c4&0xFF) * (c5&0xFF)
            q = find_binary_search( q )
            Values[q]
        end
    end

    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    def eval_7_card_hand( cards )
        best = 9999
        Perm7.each do |perm|
            q = eval_5_cards(
                cards[perm[0]], cards[perm[1]], cards[perm[2]], cards[perm[3]], cards[perm[4]])
            if q<best
                best = q
            end
        end
        best
    end
    
    def find_binary_search(key)
        low, high = 0, 4887

        while ( low <= high ) do
            mid = (high+low) >> 1;
            if ( key < Products[mid] )
                high = mid - 1;
            elsif ( key > Products[mid] )
                low = mid + 1;
            else
                return( mid );
            end
        end
        fprintf( stderr, "ERROR:  no match found; key = %d\n", key );
        return( -1 );
    end
end