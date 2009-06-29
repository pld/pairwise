module Algorithms::Prompt::Extremes
  class << self
    include Algorithms::Prompt

    # TODO: legacy algorithm IDs are on higher than their DB in database
    # update database data and sync here to match DB IDs.
    # algorithm ID
    ID = 4

    # Generate count number of prompts based on question ID and voter ID by
    # placing high rating prompt against low ratings prompts as measured by
    # winning percentage.
    # ==== Return
    # An array of prompts
    # ==== Parameters
    # question_id<int>:: Generate prompts for this question ID
    # voter_id<int>:: Generate prompts for this voter ID
    # count<int>:: Generate this number of prompts
    def prompts(question_id, voter_id, count)
      all_items = items_for_request(question_id)
      top_items = all_items.first(all_items.length / 2)
      bottom_items = all_items - top_items
      cur_top_items = []
      cur_bottom_items = []
      prompt_item_ids = {}
      # leaks with create/find in req loop
      Prompt.transaction do
        count.times do |i|
          cur_top_items = top_items.dup if cur_top_items.empty? # ensure we still have items
          cur_bottom_items = bottom_items.dup if cur_bottom_items.empty?
          prompt = prompt_for_request(question_id, voter_id, ID)
          prompt.items << cur_top_items.delete_at(rand(cur_top_items.length)) << cur_bottom_items.delete_at(rand(cur_bottom_items.length))
          redo if bad_prompt?(prompt)
          prompt_item_ids[prompt.id] = prompt.item_ids
        end
      end
      prompt_item_ids
    end
  end
end