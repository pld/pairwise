module Algorithms::Rank::Elo
  START_RATING = 1400
  K_VALUE = 32
  DRAW_SCORE = 0.5
  LOSS_SCORE = 0
  WIN_SCORE = 1

  # Calculate Elo score for all items given a user and question.
  # ==== Return
  # Array of item IDs, followed by an array of Elo scores matching to the
  # item with the same array index.
  # ==== Parameters
  # user_id<int>:: Get Elo scores for user with this ID.
  # order<string>:: If 'asc' return Elo scores in ascending order, otherwise
  # return Elo scores in descending order.
  # question_id<int>:: Get Elo scores for items in this question.
  # limit<int>:: Truncate scores returned to this number of items.
  # adj<bool>:: Use an adjusted Elo algorithm. Default true.
  def score(user_id, order, question_id, limit, adj=true)
    joins = "INNER JOIN users ON items.user_id=#{user_id}"
    joins += " INNER JOIN items_questions ON (items_questions.question_id=#{question_id} AND items_questions.item_id=items.id)" if question_id.to_i > 0
    conditions = {
      :joins => joins,
      :group => 'items.id'
    }
    items = Item.find(:all, conditions)

    conditions = {
      :conditions => { :active => false },
      :order => 'prompts.created_at',
      :include => [:items, :votes],
      :group => 'prompts.id'
    }
    conditions[:conditions].merge!(:question_id => question_id) if question_id > 0
    prompts = Prompt.all(conditions)

    elo = {}
    items.each { |item| elo[item] = START_RATING }
    @adj = adj
    prompts.each do |prompt|
      prompt.votes.each do |vote|
        # elo values static during update
        old_elo = elo.clone
        # if vote has items it has winner(s)
        unless vote.items.empty?
          vote.items.each do |item|
            lost_items = prompt.items - vote.items
            lost_items.each do |loser|
              elo[item] += adjust_elo(WIN_SCORE, old_elo[item], elo[loser])
              elo[loser] += adjust_elo(LOSS_SCORE, elo[loser], old_elo[item])
            end
          end
        else
          # otherwise consider as draw between all prompt items
          prompt.items.each do |item|
            (prompt.items - [item]).each do |other|
              elo[item] += adjust_elo(DRAW_SCORE, elo[item], old_elo[other])
            end
          end # item_ids each
        end # else
      end # votes each
    end # prompts each
    elo = (order == "asc") ? elo.sort_by { |k, v| v } : elo.sort_by { |k, v| -v }
    elo = elo.first(limit) if limit > 0
    elo.transpose
  end

  # This value is added to the previous Elo score to obtain the current score.
  # ==== Return
  # Integer which is the amount by which to adjust the Elo score
  # ==== Parameters
  # score<int>:: The adjustment value for a win, loss, or draw.
  # r_A<int>:: The Elo score of the item whose score to be adjusted.
  # r_B<int>:: The Elo score of the item whhose score is not being adjusted.
  def adjust_elo(score, r_A, r_B)
    k_value(r_A) * (score - expected_score(r_A, r_B))
  end

  # The score if A plays B.
  # ==== Return
  # Integer of the expected score.
  # ==== Parameters
  # r_A<int>:: The Elo score of item A.
  # r_B<int>:: The Elo score of item B.
  def expected_score(r_A, r_B)
    1 / (1 + 10**((r_B - r_A) / 400.0))
  end

  # Calculate the K value for an item based on if an adjusted algorithm is
  # being used and the score of the item
  # ==== Return
  # The K value for an item.
  # ==== Parameters
  # r_A<int>:: The score of the item whose K value is to be generated.
  def k_value(r_A)
    if !@adj || r_A < 2100
      K_VALUE
    elsif r_A > 2400
      16
    else
      24
    end
  end
end