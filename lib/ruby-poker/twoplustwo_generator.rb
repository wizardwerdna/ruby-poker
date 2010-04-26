require File.expand_path('../../ruby-poker', __FILE__)
require File.expand_path('../cactus_kev_value', __FILE__)
require File.expand_path('../cactus_kev_ruby_evaluator', __FILE__)


module TwoPlusTwo
    include CactusKev 
    class DagCard
        @@cards = nil

        class << self
            
            def cards
                @@cards ||= Array.new(65){|code| DagCard.new(code)}
            end
            
            def deck_of_cards
                cards.slice(0,52)
            end
            
            def for_code code
                raise "cannot find card: invalid index code (#{code.inspect})" unless code.kind_of?(Integer) && code.between?(0, 64)
                cards[code]
            end            
            
            def for_rank_and_suit rank, suit
                raise "cannot find card: invalid rank(#{rank})" unless rank.between?(0, 12)
                raise "cannot find suit: invalid suit(#{suit})" unless suit.between?(0,  4)
                cards[suit*13+rank] 
            end
        
            def for_string string
                raise "cannot find card for #{thing.inspect}" unless string.size == 2
                raise "cannot find card: invalid rank(#{string[0..0]})" unless rank = '23456789TJQKA23456789tjqka'.index(string[0..0])
                raise "cannot find card: invalid suit(#{string[1..1]})" unless suit = 'CDHSXcdhsx'.index(string[1..1])
                for_rank_and_suit (rank%13), (suit%5)
            end

            def suit_for_key key
                (key >> 4) & 0x7
            end
            
            def rank_for_key key
                key & 0xf
            end

            def for_key key
                raise "invalid key" unless (key && 0b10000000) > 0
                for_rank_and_suit rank_for_key(key), suit_for_key(key)
            end
            
            def for_integer integer
                @@integer_lut ||= Array.new(250) do |index|
                    if index < 65
                        for_code index
                    else begin
                        for_key index
                    rescue
                        nil
                    end end
                end
                @@integer_lut[integer] || raise("cannot find card: invalid key or code (#{integer})")
            end
            
            def [] thing, other_thing=nil
                case thing
                when String
                    for_string thing
                when Integer
                    for_integer thing
                else
                    raise "cannot create a card for #{thing.inspect}"
                end
            end
            alias :for :[]
        end
        
        attr_reader :suit, :rank, :code
        def initialize code
            raise "invalid card code (#{code.inspect})" unless code.kind_of?(Integer) && (0..64).member?(code)
            @code = code
            @suit = code / 13
            @rank = code % 13
        end
        
        def suit_string
            'CDHSX'[@suit..@suit]            
        end
        
        def rank_string
            '23456789TJQKA'[@rank..@rank]
        end
        
        def to_s
            "#{rank_string}#{suit_string}"
        end

        def eql? other
            self.hash == other.hash
        end
        def hash
            @memoized_hash ||= ((@suit << 4) | @rank | 0b10000000)
        end
        
        def ex_code
            52+@rank
        end
        
        def to_ex
            DagCard.for ex_code
        end
    end

    class DagHand
        attr_reader :cards, :ranks, :suits
                                  
        DAGHAND_HASH_MASK =     0x00FFFFFFFFFFFFFF      # allowing for 7-card hands, using header with
        DAGHAND_HASH_PREFIX =   0x3F00000000000000      # largest prefix that is still a FixNum
        
        class << self
            
            def valid_hand_hash_header? hand_hash
                (hand_hash&DAGHAND_HASH_PREFIX)==DAGHAND_HASH_PREFIX
            end
            
            def from_hash hand_hash
                raise "invalid hand hash (0x#{sprintf "%x",hand_hash})" unless valid_hand_hash_header?(hand_hash)
                hand_hash &= DAGHAND_HASH_MASK
                hand = []
                while hand_hash > 0
                    hand << (hand_hash & 0xff)
                    hand_hash >>= 8
                end
                new(hand.collect{|each| DagCard[each]})
            end
            
            def [] string
                raise "string must have even number of characters" unless (string.size % 2).zero?
                DagHand.new(string.gsub(/(..)/,'\1,').chop.split(',').collect{|each| DagCard[each]})
            end
            alias :for_string :[]
        end
        
        def initialize cards=[], ranks=nil, suits=nil
            if cards.class == DagCard then cards = [cards]; end
            raise "DagHands must be initialized only with arrays of DagCards" unless cards.kind_of? Array
            @cards = cards
            @ranks ||= build_ranks
            @suits ||= build_suits
            normalize
        end
        
        # Use the cactus_kev ruby evaluator to evaluate this hand
        def score
            eq_cl_code = if size == 5
                eval_5_cards(*@cards)
            elsif size == 7
                eval_n_cards_unrolled(@cards, false) #optimized for 7 cards
            elsif size == 6
                eval_n_cards_unrolled(@cards, true) #optimized for 6 cards
            elsif size > 5
                eval_n_cards_hand(@cards)
            else
                raise "not enough cards(#{size}) for evaluation"
            end
        end

        def eval_5_cards(c1, c2, c3, c4, c5)
            product = Card::Primes[c1.rank] * Card::Primes[c2.rank] * Card::Primes[c3.rank] * 
                        Card::Primes[c4.rank] * Card::Primes[c5.rank]
            result = if (c5.suit != 4) && (c1.suit == c2.suit) && (c2.suit==c3.suit) && (c3.suit==c4.suit) && (c4.suit==c5.suit)
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
        def eval_n_cards_hand( cards )
            best = EqClTable.last
            cards.combination(5).each do |each_5_card_combination|
                best = [eval_5_cards(*each_5_card_combination), best].max
            end
            best
        end
            
        def size
            cards.size
        end
        
        def build_ranks
            @ranks = Array.new(13,0)
            @cards.each{|each|@ranks[each.rank]+=1}
            @ranks
        end
        
        def build_suits
            @suits = Array.new(5,0)
            @cards.each{|each|@suits[each.suit]+=1}
            @suits
        end
        
        def has_flush
            @suits.max > 5
        end
                
        def + card
            raise "cannot add #{card.to_s}: already have a full 7-card hand" if @cards.size == 7
            raise "cannot add #{card.to_s}: already have four of this rank" if @ranks[card.rank] == 4
            raise "cannot add #{card.to_s}: already in hand" if @cards.member? card
            new_cards = @cards + [card]
            new_ranks = @ranks.clone; new_ranks[card.rank]+=1
            new_suits = @suits.clone; new_suits[card.suit]+=1
            DagHand.new new_cards, new_ranks, new_suits
        end
        alias :add_card :+
        
        def to_s
            @cards.collect{|each| each.to_s}.join('')
        end
        
        def inspect
            "DagHand.for_string('#{to_s}')"
        end
        
        def hash
            @memoized_hash ||= (@cards.inject(0){|key, card| key = key << 8 | card.hash} | DAGHAND_HASH_PREFIX)
        end

        def == other
            self.hash == other.hash
        end

        def eql? other
            other.kind_of?(DagHand) && (self.hash == other.hash)
        end
        
        # Normalize this DagHand instance.  A daghand is in normal form when it is in card-key sorted order and has no
        # irrelevant non-ex suits.  A suit is irrelevant if the card cannot make up a flush in a 7-card hand, that is,
        # if there are fewer than the handsize-2 cards in that suit
        def normalize
            # eliminate irrelevant suits
            size = @cards.size
            minsize = size - 2
            @cards.collect! do |card|
                if @suits[card.suit] >= minsize
                    card
                else
                    @suits[card.suit]-=1
                    @suits[4]+=1
                    card.to_ex
                end
            end
            # sort the hand
            @cards.sort!{|a, b| a.hash <=> b.hash}
            # c = Array.new(7){|i| @cards[i] || 0}
            # if c[0].hash<c[4].hash then t=c[0]; c[0]=c[4];c[4]=t end
            # if c[1].hash<c[5].hash then t=c[1]; c[1]=c[5];c[5]=t end
            # if c[2].hash<c[6].hash then t=c[2]; c[2]=c[6];c[6]=t end
            # if c[0].hash<c[2].hash then t=c[0]; c[0]=c[2];c[2]=t end
            # if c[1].hash<c[3].hash then t=c[1]; c[1]=c[3];c[3]=t end
            # if c[4].hash<c[6].hash then t=c[4]; c[4]=c[6];c[6]=t end
            # if c[2].hash<c[4].hash then t=c[2]; c[2]=c[4];c[4]=t end
            # if c[3].hash<c[5].hash then t=c[3]; c[3]=c[5];c[5]=t end
            # if c[0].hash<c[1].hash then t=c[0]; c[0]=c[1];c[1]=t end
            # if c[2].hash<c[3].hash then t=c[2]; c[2]=c[3];c[3]=t end
            # if c[4].hash<c[5].hash then t=c[4]; c[4]=c[5];c[5]=t end
            # if c[1].hash<c[4].hash then t=c[1]; c[1]=c[4];c[4]=t end
            # if c[3].hash<c[6].hash then t=c[3]; c[3]=c[6];c[6]=t end
            # if c[1].hash<c[2].hash then t=c[1]; c[1]=c[2];c[2]=t end
            # if c[3].hash<c[4].hash then t=c[3]; c[3]=c[4];c[4]=t end
            # if c[5].hash<c[6].hash then t=c[5]; c[5]=c[6];c[6]=t end
        end
        
        # return an array corresponding to this hand, after adding the corresponding non-ex card
        def next_hands
            DagCard.deck_of_cards.collect do |each|
                begin
                    self + each
                rescue
                    nil
                end
            end
        end
    end


    NUMBEROFCARDRANKS = 52
    MAXCARDSPERRANK = 1
    MAXCARDSPERHAND = 7
    class DagNode < Struct.new(:code, :hand, :next_links)
        class << self
            
=begin rdoc
            Build a directed acyclic graph (DAG) representing all possible poker hands of up to to_maximum_of_level
            cards, and write it as a data file of integers, in the following form:
                index       interpretation
                0           ===== DagHand hash for the empty hand
                1           index of the DagHand hash for '2C'
                2           index of the DagHand hash for '2D'
                ...
                52          index of the DagHand hash for 'AS'
                53          ==== DagHand hash for '2C'
                54          index of the empty hand, since adding '2C' to a hand already containing it is an error
                55          index of the DagHand hash for '2C3C'
                ...
                idx         index of the DagHand hash for the idx/53d enumerated hand
                idx+1       index of the DagHand hash for the idx/53d enumerated hand, adding 2C if possible, 0 otherwise
                idx+2       index of the DagHand hash for the idx/53d enumerated hand, adding 3C if possible, 0 otherwise
                ...
                idx+52      index of the Daghand hash for the idx/53d enumerated hand, adding AS if possible, 0 otherwise
                ...
                
            Several "tricks" are used to reduce the size of the data file and in-memory represnetation for evaluation:
                1) Because no further cards can be added to hands of the maximum level, the 52 entries following them
                would all be zeros!  Accordingly, we flatten the last level, so the first max-level hand would be immediately
                followed by the next hash, and so forth.  This saves considerable size.
                
                2) Because no 3 cards can be added to '2C3D4H5S' to make a flush, we do not keep track of suits for four-card
                hands having four different suits.  Thus, any combination of distinct 4-card hands with different suits are
                stored as '2X3X4X5X', saving nodes for each combination in that form.  Likewise, since '2C3C4C5CAS' cannot make 
                a spade flush, we store it as '2C3C4C5CAX',saving at three nodes at this level.  Since there are many combinations
                of cards that can follow in the next three cards, many, many nodes are saved with this solution.  The logic for
                this compression technique is embodied in the DagHand enumeration logic.
                
            The graph is built up in levels, the level number corresponding to the number of cards in the hand.  We begin with
            the empty hand, and "enumerate" all hands that can be made by adding a card to it, coding the next enumerated hand
            with the next node number.  Thus, we fill out the table for the empty hand, keeping the 52 new nodes for the next
            level, and remembering that each node has a total of 53 table entries (except for the last level).  At the end of 
            each level, we write out all the enumerated table entries, copy the unenumerated entries to our list of entries for
            the next level, and so on.  After the next to last level is "enumerated," we just go ahead and sequentially write
            the unenumerated nodes to the table, since no new cards can be added there.
            
            Index of a one-card hand can be determined as follows:
                @table[c1],
            index of the hash for a two-card hand can be traced:
                @table[@table[c1]+c2],
            index of the hash for a three-card hand can be traced:
                @table[@table[@table[c1]+c2]+c3], and so forth.
                
            Thus, the hand can be displayed for a seven card hand as follows
                index=@table[@table[@table[@table[@table[@table[@table[c1]+c2]+c3]+c4]+c5]+c6]+c7]
                puts DagHand.hash_from(@table[index]).to_s
                
            While this is a very fast, but silly and space-inefficient way to compute Daghand hand hashes, this structure can
            be used to pre-compute and quickly search for expensive computations, such as poker hand evaluations, minimum and
            maximum potential hands, and the like.  While the table is very large for 7-hand poker hands, it is still manageable,
            and this approach is ginormousy faster than non-lookup solutions.
=end
            def build_graph to_maximum_of_level=7
                @@last_node_code = -1
                @@unenumerated_nodes = []
                @@table_of_dagnodes = {}
                root_hand = DagHand.new
                root_node = node_for root_hand
                File.open("dag_table_file.dat", "w") do |file|
                    @@dag_table_data_file = file
                    to_maximum_of_level.times do |level|
                        printf STDERR, "# ====== ENUMERATING %d %d-CARD HANDS (from codes %d to %d)\n", 
                            @@unenumerated_nodes.size, @@unenumerated_nodes.first.hand.size,
                            @@unenumerated_nodes.first.code, @@unenumerated_nodes.last.code
                        @@table_of_dagnodes = {}
                        enumerate_unenumerated_nodes_for_this_level level==to_maximum_of_level-1
                    end
                end
            end

=begin rdoc
            fill in the table
=end            
            def enumerate_unenumerated_nodes_for_this_level last_enumeration
                nodes_for_enumeration = @@unenumerated_nodes
                last_node_code_for_this_level = @@last_node_code
                @@unenumerated_nodes = []
                time_of_last_report = Time.now
                last_node_reported = nodes_for_enumeration.first.code
                nodes_for_enumeration.each do |node|
                    node.next_links = DagCard.deck_of_cards.collect do |card|
                        begin
                            node_for node.hand + card
                        rescue
                            nil
                        end
                    end
                    if ((Time.now - time_of_last_report)) > 120 || (node.code % 10000).zero?
                        elapsed_time = Time.now - time_of_last_report
                        elapsed_nodes = node.code - last_node_reported + 1
                        time_of_last_report = Time.now
                        last_node_reported = node.code
                        printf STDERR, "# enumerated node #{node.code} (#{elapsed_nodes/elapsed_time} nodes per second rate since last report)\n" 
                    end
                end
                print_segment nodes_for_enumeration, @@unenumerated_nodes, last_enumeration
            end
            
            def print_segment enumerated_nodes, unenumerated_nodes, last_enumeration
                printf STDERR, "# ====== saving data for this level\n"
                first_unenumerated_code = unernumerated_nodes.first.code
                enumerated_nodes.each do |node|
                    data_array = [node.hand.hash]
                    node.next_links.each_with_index do |each, index|
                        index = if each.nil?
                            0
                        elsif last_enumeration && (each.code >= first_unenumerated_code)
                            (each.code-first_unenumerated_code) + 53*(first_unenumerated_code)
                        else
                            53 * each.code
                        end
                        data_array << index
                    end
                    @@dag_table_data_file.write data_array.pack("Q*")
                end
                if last_enumeration
                    @@dag_table_data_file.write unenumerated_nodes.collect!{|each| each.hand.hash}.pack("Q*")
                end
            end
                        
            def node_for hand
                @@table_of_dagnodes[hand] ||= unenumerated_node_for hand
            end
            
            def unenumerated_node_for hand
                node = DagNode.new(@@last_node_code+=1, hand)
                @@unenumerated_nodes << node
                node
            end
        end
    end
    
    require 'benchmark'
    class DagTable
        attr_accessor :table, :level_index
        def initialize file_name='dag_table_file.dat'
            load file_name
        end
        
        def load file_name='dag_table_file.dat'
            results = Benchmark.measure do
                printf STDERR, "# reading dag_table\n"
                open(file_name, 'r') do |file|
                    @table = file.read.unpack("Q*")
                end
                printf STDERR, "# #{@table.size} entries found.\n"
            end
            printf STDERR, "%s\n", results.to_s
        end
            
        def save file_name='dag_table_file.dat'
            results = Benchmark.measure do
                printf STDERR, "# writing dag_table\n"
                write_size = open(file_name, 'w') do |file|
                    file.write(@table.pack("Q*"))
                end
                printf STDERR, "# #{write_size} bytes written (#{write_size/8} entries).\n"
            end
            printf STDERR, "%s\n", results.to_s
        end
        
        def describe
            this_level = -1
            @level_index = []
            @table.each_with_index do |each, index|
                if DagHand.valid_hand_hash_header? each
                    hand = DagHand.from_hash each
                    if hand.size > this_level
                        this_level = hand.size
                        puts "level #{this_level} begins at #{index}, with #{hand.to_s.inspect}"
                        @level_index[this_level] = index
                    end
                end
            end
        end
        
        def fast_describe maximum_levels=7
            location = nil
            @level_index = Array.new(maximum_levels+1) do |level|
                location = if level.zero?
                    0
                else
                    @table[location+level]
                end
                puts "level #{level} begins at #{location}, with #{(DagHand.from_hash(@table[location])).inspect}"
                location
            end
        end
        
        def index_for_string string
            raise "string must have even number of characters" unless (string.size % 2).zero?
            location = 0
            string.gsub(/(..)/,'\1,').chop.split(',').each do |each|
                location = @table[location+DagCard[each].code+1]
            end
            location
        end
        
        def hands_with_index
            top_level = index_for_string('2C3C4C5C6C7C8C')
            puts "top level begins at #{top_level}"
            location = 0
            while location < top_level
                yield @table[location], location
                location+=53
            end
            while result = @table[location]
                yield result, location
                location+=1
            end
        end
        
        def [] thing, length=1, options={}
            case thing
            when String
                explore index_for_string(thing), length, options
            when Integer
                explore thing, length, options
            end
        end
        
        def explore location=0, length=1, options={}
            location = location
            length.times do |iteration|
                location += explore_one_node(location, options)
            end
        end
        alias :x :explore
        
        def explore_one_node location, options
            if DagHand.valid_hand_hash_header? @table[location]
                explore_one_hand location, options
            else
                explore_one_link location, options
            end
        end
        

        def explore_one_hand location, options
            puts "explore_one_hand(#{location.inspect}, #{options.inspect})"
            begin
                printf "%4d: 0x%016x # '%s'", location, @table[location], DagHand.from_hash(@table[location]).to_s
                if @table[location+1].nil? || @table[location+1]>=@table.size
                    1
                else
                    if options[:long]
                        printf("\n")
                        52.times do |index|
                            explore_one_link location + index + 1, options
                        end
                        53
                    else
                        next_hand_size = (DagHand.from_hash(@table[location]).size+1)*2
                        printf("\n\t\tLinks:")
                        4.times do |suit|
                            13.times do |rank|
                                printf "\n\t\t| " if (rank%6).zero?
                                index = suit*13+rank
                                printf "%s=>'%#{next_hand_size}s'(%8d) | ", 
                                    DagCard[index], DagHand.from_hash(@table[@table[location+index+1]]).to_s, @table[location+index+1]
                            end
                        end
                        printf("\n")
                        53
                    end
                end
            rescue => e
                puts e.message
                explore_one_invalid location, options
            end
        end
        
        def explore_one_link location, options
            # puts "explore_one_link(#{location.inspect}, #{options.inspect})"
            begin
                printf "%4d: %18d # %s => '%s'\n", 
                    location, @table[location], DagCard.for((location%53)-1), DagHand.from_hash(@table[@table[location]]).to_s
            rescue
                explore_one_invalid location, options
            end
            1
        end
        
        def explore_one_invalid location, options
            printf "%4d: ", location
            if @table[location].nil?
                printf "*** out of range ***\n"
            else
                printf "%18d # 0x%16x, ", @table[location], @table[location]
                if @table[@table[location]].nil?
                    printf "*** links out of range ***\n"
                else
                    printf "links to %18d (0x16x)\n", @table[@table[location]], @table[@table[location]]
                end                    
            end
            1
        end
        
        def adjust location, options
        end
        
        def to_s
            "I'm a DagTable"
        end
        
        def inspect
            begin
                "DagTable, size = #{@table.size}"
            rescue
                "DagTable"
            end
        end
        
        # Track each poker hand in the dag, replacing each hash value with its cactus_kev value'
        def evaluate
            printf STDERR, "evaluating all hand_hashes in the dag enumerating wth #hands_with_index\n"
            total_hands = 0
            total_hands_with_header = 0
            results = Benchmark.measure do
                hands_with_index do |hand, index|
                    total_hands+=1
                    printf STDERR, "# index %d, for '%s'; ", index, DagHand.from_hash(hand).to_s if (index%530000).zero?
                    @table[index] = begin
                        DagHand.from_hash(hand).score.code
                    rescue
                        0
                    end
                    if (index%530000).zero?
                        if @table[index].zero?
                            printf STDERR, "no score for this hand\n"
                        else
                            printf STDERR, "score=%d (%s)\n", @table[index], EqClTable[@table[index]].description
                        end
                    end
                end
            end
            printf STDERR, "%s\n", results.to_s
            printf STDERR, "%d hands evaluated\n", total_hands
        end
    end
end