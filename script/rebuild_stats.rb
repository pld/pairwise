include Algorithms::Rank::Ewp

rank_algo = RankAlgorithm.find(Constants::Stat::DEFAULT_RANK_ALGO)
start_score = Stat.score(rank_algo.data.to_i, 1, 1)

for question in Question.all
  for item in question.items
    ij_wins = wins_for_item_question(item, question.id)
    for j_id, i_cmp in raw_cmp_for_item_question(item, question.id)
      j_item = Item.find(j_id)
      stat = Stat.for_items(question.id, [item, j_item])
      if stat
        attr = { :votes => i_cmp }
        attr.merge!(:views => i_cmp) if stat.views < i_cmp
        stat.update_attributes(attr)
      else
        stat = Stat.create({
          :views => i_cmp,
          :votes => i_cmp,
          :question_id => question.id,
          :score => start_score,
          :rank_algorithm_id => rank_algo.id
        })
        stat.items << item << j_item
      end
      i_wins = ij_wins[j_id]
      if i_wins
        i_stat = ItemsStat.first(:conditions => { :stat_id => stat.id, :item_id => item.id })
        i_stat.update_attribute(:wins, i_wins)
        j_stat = ItemsStat.first(:conditions => { :stat_id => stat.id, :item_id => j_id })
        j_stat.update_attribute(:losses, i_wins)
      end
    end
  end
  puts "rebuilt question id: #{question.id}"
end
