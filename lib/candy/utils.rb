module Candy
  module Utils
    extend Utils

    def to_h(start = self)
      return start unless start.respond_to? :candy

      start.candy.inject({}) do |h, (k, v)|
        if v.is_a? Candy::CandyHash
          h[k] = to_h(v)
        elsif v.is_a? Candy::CandyArray
          h[k] = v.candy.map { |vv| to_h(vv) }
        else
          h[k] = v
        end
        h
      end
    end
  end
end
