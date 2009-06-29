# calculate expected winning percentage as (1/n)SUM_j(||i>j||/||i,j||)
module Algorithms::Rank::Ewp
  def ewp(item, question_id)
    stat = Stat.first({
      :select => "SUM(wins/(wins + losses)) AS score, COUNT(*) AS count",
      :conditions => "question_id=#{question_id} AND wins + losses > 0",
      :joins => "INNER JOIN items_stats ON (items_stats.stat_id=stats.id AND
        items_stats.item_id=#{item.id})"
    })
    stat_to_percent(stat)
  end

  def ewp_all(items, question_id)
    Stat.all({
      :select => "SUM(wins/(wins + losses)) AS score, COUNT(*) AS count, item_id",
      :conditions => "question_id=#{question_id} AND wins + losses > 0 AND
      item_id IN (#{items.map(&:id).join(',')})",
      :joins => "INNER JOIN items_stats ON (items_stats.stat_id=stats.id)",
      :group => 'item_id'
    })
  end

  def raw_ewp(item, items, question_id)
    i_cmp = comparisons_for_item_question(item, question_id)
    i_wins = wins_for_item_question(item, question_id)
    cmp = 0
    score = (items - [item]).inject(0) do |sum, j_item|
      i_j_cmp = i_cmp[j_item.id]
      if i_j_cmp && i_j_cmp > 0
        cmp += 1
        wins = i_wins[j_item.id]
        wins ? sum + wins / i_j_cmp : sum
      else
        sum
      end
    end
    cmp > 0 ? (100 * (score / cmp)).round(2) : 0
  end

  def comparisons_for_item_question(item, question_id)
    stat_options = {
      :select => "stats.votes, items_stats2.item_id",
      :joins => "INNER JOIN items_stats ON (items_stats.stat_id=stats.id
      AND items_stats.item_id=#{item.id}) INNER JOIN items_stats AS items_stats2
      ON (items_stats2.stat_id=stats.id AND items_stats2.item_id!=#{item.id})"
    }
    stat_options[:conditions] = { :question_id => question_id } if question_id > 0
    ::Stat.all(stat_options).inject({}) do |hash, stat|
      hash[stat.item_id.to_i] = stat.votes.to_f
      hash
    end
  end

  def raw_cmp_for_item_question(item, question_id)
    prompt_options = {
      :select => "COUNT(items_prompts.item_id) AS cmp, items_prompts.item_id",
      :group => "items_prompts.item_id",
      :joins => "INNER JOIN items_prompts ON (items_prompts.prompt_id=prompts.id
      AND items_prompts.item_id!=#{item.id}) INNER JOIN items_prompts AS
      items_prompts2 ON (items_prompts2.prompt_id=prompts.id AND
      items_prompts2.item_id=#{item.id})INNER JOIN votes ON
      (votes.prompt_id=prompts.id)"
    }
    prompt_options[:conditions] = { :question_id => question_id } if question_id > 0
    ::Prompt.all(prompt_options).inject({}) do |hash, prompt|
      hash[prompt.item_id.to_i] = prompt.cmp.to_i
      hash
    end
  end

  def wins_for_item_question(item, question_id)
    prompt_options = {
      :select => "COUNT(items_prompts.item_id) AS wins, items_prompts.item_id",
      :group => "items_prompts.item_id",
      :joins => "INNER JOIN items_prompts ON (items_prompts.prompt_id=prompts.id
      AND items_prompts.item_id!=#{item.id}) INNER JOIN votes ON
      (votes.prompt_id=prompts.id) INNER JOIN items_votes ON (items_votes.vote_id=votes.id
      AND items_votes.item_id=#{item.id})"
    }
    prompt_options[:conditions] = { :question_id => question_id } if question_id > 0
    ::Prompt.all(prompt_options).inject({}) do |hash, prompt|
      hash[prompt.item_id.to_i] = prompt.wins.to_i
      hash
    end
  end

  def stat_to_percent(stat)
    (stat.count == '0') ? 0 : (100 * (stat.score.to_f / stat.count.to_i)).round(2)
  end
end