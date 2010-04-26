require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class TestCard < Test::Unit::TestCase
  def setup
    # testing various input formats for cards
    @c1 = Card.new("9c")
    @c2 = Card.new("TD")
    @c3 = Card.new("jh")
    @c4 = Card.new("qS")
  end
  
  def test_build_from_card
    assert_equal("9c", Card.new(@c1).to_s)
  end
  
  def test_class_face_value
    assert_nil(Card.face_value('L'))
    assert_equal(13, Card.face_value('A'))
  end

  def test_build_from_value
    assert_equal(@c1, Card.new(7))
    assert_equal(@c2, Card.new(22))
    assert_equal(@c3, Card.new(37))
    assert_equal(@c4, Card.new(52))
  end

  def test_face
    assert_equal(8, @c1.face)
    assert_equal(9, @c2.face)
    assert_equal(10, @c3.face)
    assert_equal(11, @c4.face)          
  end

  def test_suit
    assert_equal(0, @c1.suit)
    assert_equal(1, @c2.suit)
    assert_equal(2, @c3.suit)
    assert_equal(3, @c4.suit)
  end

  def test_value
    assert_equal(7, @c1.value)
    assert_equal(22, @c2.value)
    assert_equal(37, @c3.value)
    assert_equal(52, @c4.value)
  end
  
  def test_code0
    assert_equal(7, @c1.code0)
    assert_equal(21, @c2.code0)
    assert_equal(35, @c3.code0)
    assert_equal(49, @c4.code0)
  end
  
  def test_code1
    assert_equal(8, @c1.code1)
    assert_equal(22, @c2.code1)
    assert_equal(36, @c3.code1)
    assert_equal(50, @c4.code1)
  end
  
  def test_natural_value
    assert_equal(1, Card.new("AC").natural_value)
    assert_equal(15, Card.new("2D").natural_value)
    assert_equal(52, Card.new("KS").natural_value)
  end

  def test_comparison
    assert(@c1 < @c2)
    assert(@c3 > @c2)
  end
  
  def test_equals
    c = Card.new("9h")
    assert_not_equal(@c1, c)
    assert_equal(@c1, @c1)
  end
  
  def test_hash
    assert_equal(15, @c1.hash)
  end
  
  def test_cactus_kev_value
     assert_equal(Card.new('2c').cactus_kev_card_value, 0b00000000000000010001000000000010)
     assert_equal(Card.new('3c').cactus_kev_card_value, 0b00000000000000100001000100000011)
     assert_equal(Card.new('Ac').cactus_kev_card_value, 0b00010000000000000001110000101001)
     assert_equal(Card.new('2s').cactus_kev_card_value, 0b00000000000000011000000000000010)
     assert_equal(Card.new('3s').cactus_kev_card_value, 0b00000000000000101000000100000011)
     assert_equal(Card.new('As').cactus_kev_card_value, 0b00010000000000001000110000101001)
  end
end