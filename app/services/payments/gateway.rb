module Payments
  class Gateway
    def create(command)
      raise NotImplementedError
    end
  end
end
