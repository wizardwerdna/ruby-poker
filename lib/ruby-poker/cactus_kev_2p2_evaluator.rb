require 'benchmark'
require 'zlib'
require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_five_card_evaluator_tables', __FILE__)

=begin rdoc
    CactusKev2p2Evaluator (original), using a very large lookup table to evaluate hands.  The table
    is given as a simple array of words, gzipped.  The table represents a directed acyclic graph, with
    roots corresponding to single card hands, with 2C at index 53, 3C at index 106, and so forth.  Each principal
    node is followed by 52 words which correspond to indeces of nodes for hands obtained by 2C, 3C and so forth.
    The value at the node is the CactusKev equivalence class index corresponding to each hand.  Thus, if you have
    an n-card hand represented by integers c1..cn, you can obtain the location of the hand value at..
    
            location = t[t[...t[t[t[c1]+c2]+c3...]+cn-1]+cn]
            
    and thus the evaluation can be found at
    
            EqClTable[t[location]]
            
    In addition to being lightning fast, this is also a very useful solution for evaluating partial hands across
    many further continuations.  Thus, you can evaluate a flop, f1f2f3 against two hands with hole cards h1a, h1b
    and h2a, h2b, respectively, to obtain locations for the partial evaluations of each hand, and then generate
    exhaustively all turns and rivers, requiring only two indexes more for each exhaustive hand to obtain evaluations.
=end
class CactusKev2p2Evaluator < CactusKev::CactusKevValueEvaluator
    include CactusKev
    
    class << self
        @@t = nil
        def table from_file_name='eval_dag_table_file.dat.gz'
            @@t ||= begin
                results = Benchmark.measure do
                    printf STDERR, "# reading dag_table\n"
                    Zlib::GzipReader.open(File.expand_path("../#{from_file_name}", __FILE__)) do |gz|
                        @@t = gz.read.unpack("Q*")
                    end
                    printf STDERR, "# #{@@t.size} entries found.\n"
                end
                printf STDERR, "%s\n", results.to_s
                @@t
            end
        end
    end
    self.table 'eval_dag_table_file.dat.gz'    
    
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