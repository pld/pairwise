class Array
  # evaluate on outside of loop
  def sumup(on = nil)
    on ? self.inject(0) { |sum, el| sum += el.send(on).to_f } : self.inject(0) { |sum, el| sum += el.to_f }
  end

  def closure
    self.inject(self.first) { |closure, el| closure &= el; closure }
  end
end