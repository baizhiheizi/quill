require 'aasm'

class PreOrder
  include AASM
  
  aasm column: :state do
    state :drafted, initial: true
    state :paid
    
    event :pay, after_commit: :broadcast_to_views do
      transitions from: :drafted, to: :paid
    end
  end
end

puts PreOrder.aasm.events.find { |e| e.name == :pay }.options.inspect
