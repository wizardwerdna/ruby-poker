require 'benchmark'
require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_five_card_evaluator_tables', __FILE__)

=begin rdoc
    CactusKevRubyEvaluator (original), using a direct ruby hash from the product of prime numbers
    corresponding to each card.  Because so much of the heavy lifting is passed to the machine
    language in the interpreter, I thought this would be a huge win, but despite its simplicity,
    it is a fair bit slower than the perfect hash cactus kev solution.
=end
class CactusKev2p2Evaluator < CactusKev::CactusKevValueEvaluator
    include CactusKev
    
    class << self
        @@t = nil
        def table from_file_name='eval_dag_table_file.dat'
            @@t ||= begin
                results = Benchmark.measure do
                    printf STDERR, "# reading dag_table\n"
                    open(File.expand_path("../#{from_file_name}", __FILE__), 'r') do |file|
                        @@t = file.read.unpack("Q*")
                    end
                    printf STDERR, "# #{@@t.size} entries found.\n"
                end
                printf STDERR, "%s\n", results.to_s
                @@t
            end
        end
    end
    self.table 'eval_dag_table_file.dat'
    
    
    def score
        cards = @hand.hand
        size = cards.size
        eq_cl_code = if size == 5
            eval_5_cards(*cards)
        elsif size == 6
            eval_6_cards(*cards)
        elsif size == 7
            eval_7_cards(*cards)
        elsif size > 5
            eval_n_cards_hand(cards)
        else
            raise "not enough cards(#{size}) for evaluation"
        end
    end
    
private
    def eval_5_cards(c1, c2, c3, c4, c5)
        EqClTable[@@t[
            @@t[@@t[@@t[@@t[@@t[c1.code1]+c2.code1]+c3.code1]+c4.code1]+c5.code1]
        ]]
    end
    def eval_6_cards(c1, c2, c3, c4, c5, c6)
        EqClTable[@@t[
            @@t[@@t[@@t[@@t[@@t[@@t[c1.code1]+c2.code1]+c3.code1]+c4.code1]+c5.code1]+c6.code1]
        ]]
    end
    def eval_7_cards(c1, c2, c3, c4, c5, c6, c7)
        EqClTable[@@t[
            @@t[@@t[@@t[@@t[@@t[@@t[@@t[c1.code1]+c2.code1]+c3.code1]+c4.code1]+c5.code1]+c6.code1]+c7.code1]
        ]]
    end
    
    # evaluate each permutation using eval_5cards_fast, returning the best result as an integer
    def eval_n_cards_hand( cards )
        best = EqClTable.last
        cards.combination(5).each do |each_5_card_combination|
            best = [eval_5_cards(*each_5_card_combination), best].max
        end
        best
    end
end