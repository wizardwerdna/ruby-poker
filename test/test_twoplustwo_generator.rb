# assert_equal("As Ah Ac 9c 2d", @trips.sort_using_rank)
# assert_instance_of Card, @trips.hand[0]
# assert_nothing_raised RuntimeError do
#   PokerHand.new("3s 3s")
# end
require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require File.expand_path('../../lib/ruby-poker/twoplustwo_generator', __FILE__)

TWOCLUBSCODE = 0
THREECLUBSCODE = 1
FOURCLUBSCODE = 2
FIVECLUBSCODE = 3
SIXCLUBSCODE = 4
ACECLUBSCODE = 12
ACEDIAMONDSCODE = 25
ACEHEARTSCODE = 38
ACESPADESCODE = 51
TWOEXESCODE = 52
ACEEXESCODE = 64

class TestTwoPlusTwoGenerator < Test::Unit::TestCase
    include TwoPlusTwo
    context "A DagCard instance" do
        context "when first created" do
  
            should "make instance when initialized with valid data" do
                assert_instance_of DagCard, DagCard.new(TWOCLUBSCODE)
                assert_instance_of DagCard, DagCard.new(ACECLUBSCODE)
                assert_instance_of DagCard, DagCard.new(ACESPADESCODE)
                assert_instance_of DagCard, DagCard.new(TWOEXESCODE)
                assert_instance_of DagCard, DagCard.new(ACEEXESCODE)
            end

            should "raise RuntimeError when initialized with invalid data" do
                assert_raises(RuntimeError){DagCard.new(TWOCLUBSCODE-1)}
                assert_raises(RuntimeError){DagCard.new(ACEEXESCODE+1)}
                assert_raises(RuntimeError){DagCard.new(DagHand.new)}
            end
        end
        
        context "after creation" do
            setup do
                @two_clubs = DagCard.new(TWOCLUBSCODE)
                @ace_clubs = DagCard.new(ACECLUBSCODE)
                @ace_spades = DagCard.new(ACESPADESCODE)
                @two_exes = DagCard.new(TWOEXESCODE)
                @ace_exes = DagCard.new(ACEEXESCODE)
            end
            
            should "return a descriptive string" do
                assert_equal '2C', @two_clubs.to_s
                assert_equal 'AC', @ace_clubs.to_s
                assert_equal 'AS', @ace_spades.to_s
                assert_equal '2X', @two_exes.to_s
                assert_equal 'AX', @ace_exes.to_s
            end
            
            should "return the suit value" do
                assert_equal 0, @two_clubs.suit
                assert_equal 0, @ace_clubs.suit
                assert_equal 3, @ace_spades.suit
                assert_equal 4, @two_exes.suit
                assert_equal 4, @ace_exes.suit
            end
            
            should "return the rank value" do
                assert_equal 0, @two_clubs.rank
                assert_equal 12, @ace_clubs.rank
                assert_equal 12, @ace_spades.rank
                assert_equal 0, @two_exes.rank
                assert_equal 12, @ace_exes.rank
            end
            
            should "return the key encoded value" do
                assert_equal 0b10000000, @two_clubs.hash
                assert_equal 0b10001100, @ace_clubs.hash
                assert_equal 0b10111100, @ace_spades.hash
                assert_equal 0b11000000, @two_exes.hash
                assert_equal 0b11001100, @ace_exes.hash
            end
        end
        
        context "as set of singletons holder" do
            setup do
                @two_clubs = DagCard[TWOCLUBSCODE]
                @ace_clubs = DagCard[ACECLUBSCODE]
                @ace_spades = DagCard[ACESPADESCODE]
                @two_exes = DagCard[TWOEXESCODE]
                @ace_exes = DagCard[ACEEXESCODE]
            end
            
            should "return a descriptive string" do
                assert_equal '2C', @two_clubs.to_s
                assert_equal 'AC', @ace_clubs.to_s
                assert_equal 'AS', @ace_spades.to_s
                assert_equal '2X', @two_exes.to_s
                assert_equal 'AX', @ace_exes.to_s
            end
            
            should "return the suit value" do
                assert_equal 0, @two_clubs.suit
                assert_equal 0, @ace_clubs.suit
                assert_equal 3, @ace_spades.suit
                assert_equal 4, @two_exes.suit
                assert_equal 4, @ace_exes.suit
            end
            
            should "return the rank value" do
                assert_equal 0, @two_clubs.rank
                assert_equal 12, @ace_clubs.rank
                assert_equal 12, @ace_spades.rank
                assert_equal 0, @two_exes.rank
                assert_equal 12, @ace_exes.rank
            end
            
            should "return the key encoded value" do
                assert_equal 0b10000000, @two_clubs.hash
                assert_equal 0b10001100, @ace_clubs.hash
                assert_equal 0b10111100, @ace_spades.hash
                assert_equal 0b11000000, @two_exes.hash
                assert_equal 0b11001100, @ace_exes.hash
            end
            
            should "return the correct ex card" do
                assert_equal @two_exes, @two_clubs.to_ex
                assert_equal @ace_exes, @ace_clubs.to_ex
                assert_equal @ace_exes, @ace_spades.to_ex
                assert_equal @two_exes, @two_exes.to_ex
                assert_equal @ace_exes, @ace_exes.to_ex
            end
            
            should "build a card from a string" do
                assert_equal @ace_spades, DagCard["AS"]
                assert_equal @two_clubs, DagCard["2C"]
                assert_equal @ace_clubs, DagCard["AC"]
                assert_equal @ace_exes, DagCard["AX"]
            end
        end
    end
    
    context "A DagHand instance" do
        context "when first created" do
            should "make an instance when initialized with valid data" do
                assert_instance_of DagHand, DagHand.new
                assert_instance_of DagHand, DagHand.new(DagCard.new(ACECLUBSCODE))
                assert_instance_of DagHand, DagHand.new([DagCard.new(ACECLUBSCODE)])
                assert_instance_of DagHand, DagHand.new(DagCard['2C'])
                assert_instance_of DagHand, DagHand.new([DagCard['2C'], DagCard['2D']])
                assert_instance_of DagHand, DagHand.for_string("2C2D")
            end
            should "raise an error when initialized with invalid data" do
                assert_raises(RuntimeError) {DagHand.new 1}
                assert_raises(RuntimeError) {DagHand.new DagCard['XX']}
                # assert_raises(RuntimeError) {DagHand.new [1]}  can't really afford to pay for the check here.
            end
        end
        context "upon creation" do
            setup do
                @key_for_2C = DagCard['2C'].hash
                @key_for_2D = DagCard['2D'].hash
                @hand_2C = DagHand['2C']
                @hand_2C_2D = DagHand['2C2D']
            end

            should "compute the the hash correctly" do
                assert_equal DagCard['2C'].hash | DagHand::DAGHAND_HASH_PREFIX, DagHand['2C'].hash
                assert_equal(((DagCard['2C'].hash << 8) | DagCard['2D'].hash) | DagHand::DAGHAND_HASH_PREFIX, DagHand['2C2D'].hash)
                assert_equal(((DagCard['2C'].hash << 8) | DagCard['2D'].hash) | DagHand::DAGHAND_HASH_PREFIX, DagHand['2D2C'].hash)
            end
            
            should "create instances properly from hash code" do
                assert_equal '2C2D2H', DagHand.from_hash(DagHand['2C2D2H'].hash).to_s
                assert_equal '2C2D2H', DagHand.from_hash(DagHand.from_hash(DagHand['2C2D2H'].hash).hash).to_s
            end
            
            should "compute equality correctly" do
                assert DagHand.new.eql?(DagHand.new)
                assert_equal DagHand.new, DagHand.new
                assert_equal DagHand['2C'], DagHand['2C']
                assert_not_equal DagHand['2C'], DagHand['2D2C']
                assert_equal DagHand['2D2C'], DagHand['2D2C']
                assert_equal DagHand['2C3C4C5CAS'], DagHand['2C3C4C5CAH']
                assert_equal DagHand['2C3C4C5CAS'], DagHand['2C3C4C5CAX']
                assert_not_equal DagHand['2C3D4H5SAS'], DagHand['2C3C4C5CAS']
            end
            
            should "display the cards in the hand" do
                assert_equal "2C", DagHand["2C"].to_s
                assert_equal "2C2D", DagHand["2C2D"].to_s
                assert_not_equal "2C3D4H5SAS", DagHand['2C3D4H5SAS'].to_s
                assert_equal "2C3C4C5CAX", DagHand['2C3C4C5CAS'].to_s
            end
            
            should "add cards properly" do
                assert_equal DagHand["2C"], DagHand.new + DagCard["2C"]
                assert_equal DagHand["2C2D"], DagHand["2C"] + DagCard["2D"]
                assert_equal DagHand["2C2D"], DagHand["2D"] + DagCard["2C"]
                assert_equal DagHand["2C2D2H"], DagHand["2C2D"] + DagCard["2H"]
                assert_equal DagHand["2C2D2H2S"], DagHand["2C2D2H"] + DagCard["2S"]
                # all cards irrelevant after 5
                assert_equal DagHand["2C3D4H5SAS"], DagHand["2C3D4H5S"] + DagCard["AS"]
                assert_equal DagHand["2C3D4H5SAS"], DagHand["2C3D4H5S"] + DagCard["AC"]
                assert_equal DagHand["2C3D4H5SAS"], DagHand["2C3D4H5S"] + DagCard["AD"]
                assert_equal DagHand["2C3D4H5SAS"], DagHand["2C3D4H5S"] + DagCard["AH"]
                # spades and hearts irrelevant after 5
                assert_equal DagHand["2C3C4D4HAS"], DagHand["2C3C4D4D"] + DagCard["AS"]
                assert_equal DagHand["2C3C4D4HAS"], DagHand["2C3C4D4D"] + DagCard["AH"]
                assert_not_equal DagHand["2C3C4D4DAS"], DagHand["2C3C4D4D"] + DagCard["AD"]
                assert_not_equal DagHand["2C3C4D4DAS"], DagHand["2C3C4D4D"] + DagCard["AC"]
            end
            
            should "not add invalid cards" do
                # can't add same card
                assert_raises(RuntimeError) {DagHand['2C'] + DagCard['2C']}
                assert_raises(RuntimeError) {DagHand['2C2D'] + DagCard['2D']}
                assert_raises(RuntimeError) {DagHand['2C2D2H'] + DagCard['2H']}
                assert_raises(RuntimeError) {DagHand['2C2D3D4D'] + DagCard['2D']}
                # but can add same card when its suit has become irrelevant, because first card turns into an ex
                assert_nothing_thrown(RuntimeError) {DagHand['2C2D3D4D'] + DagCard['2C']}
                # cannot add 5th card of a rank, even thoug there are exes
                assert_raises(RuntimeError) {DagHand['2C2D2H2S'] + DagCard['2S']}
                assert_raises(RuntimeError) {DagHand['2X2X2X2X'] + DagCard['2S']}
                assert_raises(RuntimeError) {DagHand['2X2X2X2X'] + DagCard['2C']}
                assert_raises(RuntimeError) {DagHand['2X2X2X2X'] + DagCard['2D']}
                assert_raises(RuntimeError) {DagHand['2X2X2X2X'] + DagCard['2H']}
                assert_raises(RuntimeError) {DagHand['2X2X2X2X'] + DagCard['2S']}
            end
        end
    end
end