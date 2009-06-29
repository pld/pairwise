module Algorithms::Prompt::Random
  class << self
    include Algorithms::Prompt

    # algorithm ID
    ID = 2

    # Generate count number of random prompts based on question ID and voter ID.
    # ==== Return
    # An array of prompts
    # ==== Parameters
    # question_id<int>:: Generate prompts for this question ID
    # voter_id<int>:: Generate prompts for this voter ID
    # count<int>:: Generate this number of prompts
    def prompts(question_id, voter_id, count)
      all_items = items_for_request(question_id)
      items = []
      prompt_item_ids = {}
      # leaks with create/find in req loop
      Prompt.transaction do
        count.times do |i|
          items = all_items.dup if items.length < 2 # ensure we still have items
          prompt = prompt_for_request(question_id, voter_id, ID)
          item = items.delete_at(rand(items.length))
          prompt.items << item << items.delete_at(rand(items.length))
          redo if bad_prompt?(prompt)
          prompt_item_ids[prompt.id] = prompt.item_ids
        end
      end
      prompt_item_ids
    end
  end
end