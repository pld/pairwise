module Algorithms::Prompt::Popular
  class << self
    include Algorithms::Prompt

    # algorithm ID
    ID = 3

    # Generate count number of primed prompts based on question ID, voter ID
    # and stats.
    # ==== Return
    # Hash with prompt IDs as keys and item IDs for that prompt as values.
    # ==== Parameters
    # question_id<int>:: Generate prompts for this question ID
    # voter_id<int>:: Generate prompts for this voter ID
    # count<int>:: Generate this number of prompts
    def prompts(question_id, voter_id, count)
      result = ActiveRecord::Base.connection.execute(
        "SELECT id,score FROM stats WHERE question_id=#{question_id} ORDER BY score;"
      )
      # TODO: choose min value with more justification
      return nil unless result.num_rows > 2
      # make all stats positive by adding |min(stats)| + 1 to all stats
      prompt_item_ids = {}
      norm = cur = 0
      stats = []
      stat = result.fetch_hash
      min = stat['score'].to_f.abs + 1
      while !stat.nil?
        norm += (adj = stat['score'].to_f + min)
        stats << [stat['id'].to_i, [cur, cur += adj]]
        stat = result.fetch_hash
      end
      result.free
      Prompt.transaction do
        count.times do |i|
          prompt = prompt_for_request(question_id, voter_id, ID)
          # choose the stat [0] <= r < [1]
          r = rand(norm)
          # detect treats hash as [key, value] array
          stat_id = stats.detect { |stat| stat[1][0] <= r && r < stat[1][1] }[0]
          item_ids = Stat.find(stat_id).item_ids
          prompt.item_ids = item_ids
          redo if bad_prompt?(prompt)
          prompt_item_ids[prompt.id] = item_ids
        end
      end
      prompt_item_ids
    end
  end
end
    