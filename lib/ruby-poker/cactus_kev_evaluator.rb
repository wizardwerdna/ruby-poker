require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_five_card_evaluator_tables', __FILE__)

class CactusKevEvaluator < CactusKev::CactusKevValueEvaluator
    include CactusKev
    
    def score
        EqClTable[eval_5cards(*@hand.to_a.map{|each| each.cactus_kev_card_value})]
    end
    
private
    
    def eval_5cards( c1, c2, c3, c4, c5 )
        # puts "eval_5cards(#{c1.inspect},#{c2.inspect},#{c3.inspect},#{c4.inspect},#{c5.inspect})"
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

    def eval_7hand( hand )
        best = 9999
        subhand = Array.new(5, nil)
    
        for i in 0..20
            for j in 0..4
    			subhand[j] = hand[ Perm7[i][j] ];
    		end
    		q = eval_5hand_fast( subhand );
    		if ( q < best )
    			best = q;
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

    # def eval_5cards_fast( c1, c2, c3, c4, c5)
    #     q = (c1 | c2 | c3 | c4 | c5) >> 16;
    #     case
    #     when (c1 & c2 & c3 & c4 & c5 & 0xf000) > 0
    #         Flushes[q]
    #     when (s = Unique5[q]) > 0
    #         s
    #     else
    #         q = (c1&0xFF) * (c2&0xFF) * (c3&0xFF) * (c4&0xFF) * (c5&0xFF)
    #         q = find_perfect_hash( q )
    #         Hash_values[q]
    #     end
    # end
    # 
    # def eval_5hand( hand )
    #     eval_5cards(*hand)
    # end
    # 
    # def eval_5hand_fast( hand )
    #     eval_5cards_fast(*hand)
    # end
    # def find_perfect_hash(u)
    #     u = (u+0xe91aaa35) & 0xffffffff
    #     u ^= u >> 16;
    #     u = (u + (u << 8)) & 0xffffffff
    #     u ^= u >> 4;
    #     b  = (u >> 8) & 0x1ff;
    #     a  = ((u + (u << 2))&0xffffffff) >> 19;
    #     r  = a ^ Hash_adjust[b];
    #     return r;
    # end
end