class VotesController < ApplicationController
  include Algorithms::Rank::Elo
  before_filter :force_xml

  # GET /votes/list
  # ==== Return
  # Array of votes.
  # ==== Options (params)
  # question_id<String>:: Converted to integer. Optional question id of votes.
  # item_id<String>:: Converted to integer. Optional item id of votes. Must
  # belong to user.
  # ==== Raises
  # PermissionError:: If question of item does not belong to user.
  def list
    conditions = { 'questions.user_id' => current_user.id }
    conditions.merge!('questions.id' => params[:question_id]) if params[:question_id].to_i > 0
    item_id = params[:item_id].to_i
    conditions.merge!('items_prompts.item_id' => item_id) if item_id > 0
    options = {
      :include => [{:prompt => [:items, :question]}],
      :conditions => conditions,
      :order => 'votes.id'
    }
    options[:limit] = params[:limit] if params[:limit].to_i > 0
    @votes = Vote.all(options)
    if item_id > 0
      options[:conditions].delete('items_prompts.item_id')
      options[:conditions].merge!('items.id' => item_id)
      options[:joins] = "INNER JOIN items_prompts ON (items_prompts.prompt_id=prompts.id AND items_prompts.item_id=#{item_id})"
      options[:include] = [:items, {:prompt => :question}]
      @votes_items = Vote.all(options)
    end
  end

  # GET /votes/add
  # ==== Return
  # Vote.
  # ==== Options (params)
  # prompt_id<String>:: Converted to integer. Prompt id of vote. Must belong
  # to user.
  # skip<String>:: Vote is skip if value '1'.
  # item_id<String>:: Item ids of winners.  Integer or comman seperated list
  # integers.  Any zero values are removed.
  # voter_id<String>:: Converted to integer.  Voter id or anonymous 0 voter.
  # Must belong to user.
  # ==== Raises
  # ArgumentError:: If no prompt id, prompt doesn't belong to user, or no
  # voter id.
  # PermissionError:: If voter does not belong to user.
  def add
    prompt_id = params[:prompt_id].to_i
    item_ids = (params[:item_id] && params[:item_id].split(',').map(&:to_i).reject(&:zero?)) || []
    skip = (params[:skip] == '1' || item_ids.empty?)
    voter_id = params[:voter_id].to_i
    # can only vote on your questions' prompts, requires voter
    raise ArgumentError unless prompt_id > 0 && current_user.prompts.exists?(prompt_id) && voter_id
    # if non-anonymous voter user must own voter
    raise PermissionError if voter_id > 0 && Voter.find(voter_id).user_id != current_user.id
    prompt = Prompt.find(prompt_id)
    prompt.update_attribute(:active, false) if prompt.active
    question_id = prompt.question_id
    all_items = prompt.items
    items = []
    old_elos = all_items.inject({}) do |hash, item|
      hash[item.id] = item.iq(question_id).position
      hash
    end
    @adj = true
    attributes = { :prompt_id => prompt_id, :voter_id => voter_id }
    attributes[:tracking] = params[:tracking] unless params[:tracking].nil?
    attributes[:response_time] = params[:response_time].to_i if params[:response_time].to_i > 0
    @vote = Vote.new(attributes)
    raise ArgumentError unless @vote.valid?
    if skip == true
      all_items.each do |item|
        iq = item.iq(question_id)
        iq.increment!(:ratings)
        (all_items - [item]).each do |other|
          iq.increment!(:position, adjust_elo(DRAW_SCORE, iq.position, old_elos[other.id]))
        end
      end
    else
      items = Item.find(item_ids)
      # vote invalid if any items not in prompt
      raise ArgumentError unless (items - all_items).empty?
      items.each do |item|
        iq = item.iq(question_id)
        iq.update_attributes({ :ratings => iq.ratings + 1, :wins => iq.wins + 1 })
        (all_items - items).each do |loser|
          iq.increment!(:position, adjust_elo(WIN_SCORE, old_elos[item.id], old_elos[loser.id]))
          loser.iq(question_id).increment!(:position, adjust_elo(LOSS_SCORE, old_elos[loser.id], old_elos[item.id]))
        end
      end
      (all_items - items).each do |item|
        iq = item.iq(question_id)
        iq.update_attributes({ :ratings => iq.ratings + 1, :losses => iq.losses + 1 })
      end
    end
    Stat.vote(question_id, all_items, items)
    @vote.save!
    @vote.items << items if defined?(items) && items
  end
end
