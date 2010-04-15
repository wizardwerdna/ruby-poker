module Naive
    class NaiveScore
        attr_reader :value
        def initialize array
            @value = array
        end
        def <=> other
            self.value[0].compact <=> other.value[0].compact
        end
        def arranged_hand
            @value[1]
        end
        def cons
            @value[0]
        end
        def kind
            @value[0][0]
        end
    end
end