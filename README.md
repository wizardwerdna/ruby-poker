# Poker library in Ruby

Author: [Andrew C. Greenberg](http://lawhacker.com)  
Email: andrewcgreenberg [at] gmail.com  
GitHub: [https://github.com/wizarderdna/ruby-poker](https://github.com/wizarderdna/ruby-poker)  

Forked from [Rob Olson's](http://thinkingdigitally.com) excellent first cut at a ruby-native evaluator.

## Description

Ruby-Poker handles the logic for getting the rank of a poker hand. It can also be used to compare two or more hands to determine which hand has the highest poker value.

Card representations can be passed to the PokerHand constructor as a string or an array. Face cards (cards ten, jack, queen, king, and ace) are created using their letter representation (T, J, Q, K, A).

Plural evaluators may be installed and tested for comparative accuracy and efficiency.  By default, HurleyEvaluator, the Patrick Hurley algorithm (slow, but straightforward to understand and space-efficient) is used.  Other evaluators include:

**CactusKevBinarySearchEvaluator** - The original Cactus-Kev evaluator, which exploits four smallish (about 10k FixedInt) lookup tables to quickly compute a value, but only for 5-card hands.  The algorithm is extended to 6- and 7-card hands by doing evaluations of each 5-card combination.  Even doing 21 times as many valuations, the Cactus-Kev evaluator is considerably faster than the Hurley algorithm for 7-card hands.

**CactusKevEvaluator** - The original Cactus-Kev evaluator, replacing the binary search lookup in the third table with a perfect hash.

**CactusKevRubyEvaluator** - A ruby-based variation on the CactusKev solution, using a single table and ruby hashes.  This turned out to run slightly faster than the CK evaluator.  It, too, is limited to 5-card hands, using an unrolled version of the combination solution for original CK.

**CactusKev2p2Evaluator** - Carrying lookup tables to the limit, this evaluator is based on the two-plus-two valuation optimization thread, using a monstrously large lookup table that represents a state machine for 7-card hands.  Unlike the previous tables, it does not require any special processing beyond serially looking up (a single table index for each card) the cards in the hand to produce a hand valuation score.  This runs significantly faster (40x) than the Hurley evaluator:

```text
7-card shootout (100,000 random hands)
                                      user     system      total        real   ms per hand
CactusKev2p2Evaluator             1.930000   0.080000   2.010000 (  2.006648)   0.02006648
CactusKevEvaluator               12.280000   0.100000  12.380000 ( 12.382839)   0.12382839
CactusKevRubyEvaluator           14.290000   0.120000  14.410000 ( 14.404539)   0.14404539
CactusKevBinarySearchEvaluator   26.210000   0.090000  26.300000 ( 26.298261)   0.26298261
HurleyEvaluator                  88.100000   1.260000  89.360000 ( 89.362515)   0.89362515
```

## Install

    gem install ruby-poker

## Example

```ruby
require 'rubygems'
require 'ruby-poker'

hand1 = PokerHand.new("8H 9C TC JD QH") # uses the hurley evaluator by default
require 'ruby-poker/cactus_kev_2p2_evaluator' # loads the monstrously large table for 2p2
hand2 = PokerHand.new(["3D", "3C", "3S", "KD", "AH"], CactusKev2p2Evaluator) # uses the super-fast two plus two evaluator 
puts hand1                # => 8h 9c Tc Jd Qh (Straight)
puts hand1.just_cards     # => 8h 9c Tc Jd Qh
puts hand1.rank           # => Straight
puts hand2                # => 3d 3c 3s Kd Ah (Three of a kind)
puts hand2.rank           # => Three of a kind
puts hand1 > hand2        # => true
```

## Duplicates

By default ruby-poker will not raise an exception if you add the same card to a hand twice. You can tell ruby-poker to not allow duplicates by doing the following

```ruby
PokerHand.allow_duplicates = false
```
    
Place that line near the beginning of your program. The change is program wide so once `allow_duplicates` is set to `false`, _all_ poker hands will raise an exception if a duplicate card is added to the hand.

## Compatibility

Ruby-Poker is compatible with Ruby 1.8.6 and Ruby 1.9.1.

## History

In the 0.2.0 release Patrick Hurley's Texas Holdem code from [http://www.rubyquiz.com/quiz24.html](http://www.rubyquiz.com/quiz24.html) was merged into ruby-poker.

## License

This is free software; you can redistribute it and/or modify it under the terms of the BSD license. See [LICENSE](LICENSE) for more details.
