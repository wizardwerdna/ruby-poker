require 'benchmark'
require File.expand_path('../../lib/ruby-poker', __FILE__)
require File.expand_path('../../lib/ruby-poker/hurley_evaluator', __FILE__)
require File.expand_path('../../lib/ruby-poker/hurley_tare_evaluator', __FILE__)
require File.expand_path('../../lib/ruby-poker/cactus_kev_evaluator', __FILE__)
require File.expand_path('../../lib/ruby-poker/cactus_kev_tare_evaluator', __FILE__)
require File.expand_path('../../lib/ruby-poker/cactus_kev_ruby_evaluator', __FILE__)
require File.expand_path('../../lib/ruby-poker/cactus_kev_2p2_evaluator', __FILE__)
require File.expand_path('../../lib/ruby-poker/cactus_kev_binary_search_evaluator', __FILE__)

Deck = []
Card::SUITS.each_char do |suit|
    Card::FACES[1..-1].each_char do |face|
        Deck << Card.new(face+suit)
    end
end

def benchmark_evaluation_of_all_5_card_hands evaluator
    puts "==="
    puts "Performance and validation tests for #{evaluator}"
    first_card = Deck.last
    categories = {}
    beginning_time = Time.now
    Benchmark.bm(40) do |bm|
        Deck.combination(5).each_slice(100000) do |slice|
            bm.report(evaluator.to_s + "(#{slice.first[0]})") do
                slice.each do |each_hand|
                    kind = PokerHand.new(each_hand, evaluator).score.kind
                    categories[kind] ||= 0
                    categories[kind] += 1
                end
            end
        end
    end
    puts "Elapsed Time: #{Time.now - beginning_time}"
    printf("kind hits\n")
    categories.keys.sort.each do |key|
        printf "%4d %7d\n", key, categories[key]
    end
end

def evaluate_1000000_random_5_card_hands evaluator
    (1..100000).each do
        PokerHand.new(Deck.shuffle[0..6], evaluator).score
    end
end

def evaluate_1000000_random_7_card_hands evaluator
    (1..100000).each do
        PokerHand.new(Deck.shuffle[0..6], evaluator).score
    end
end

TareEvaluators = [CactusKevTareEvaluator, HurleyTareEvaluator]
Evaluators = [CactusKev2p2Evaluator, CactusKevEvaluator, CactusKevRubyEvaluator, CactusKevBinarySearchEvaluator, HurleyEvaluator]

puts "Tareweight Evaluators (100,000 random hands)"
Benchmark.bm(40) do |bm|
    TareEvaluators.each do |evaluator|
        bm.report(evaluator.to_s + "(5 card hands)") {evaluate_1000000_random_5_card_hands evaluator}
        bm.report(evaluator.to_s + "(7 card hands)") {evaluate_1000000_random_7_card_hands evaluator}
    end
end
puts
puts "==================="
puts
puts "7-card shootout (100,000 random hands)"
Benchmark.bm(40) do |bm|
    Evaluators.each do |evaluator|
        bm.report(evaluator.to_s + "") {evaluate_1000000_random_7_card_hands evaluator}
    end
end
puts
puts "==================="
puts
puts "5-card shootout (exhaustive)"
Evaluators.each do |evaluator| 
    benchmark_evaluation_of_all_5_card_hands evaluator
end