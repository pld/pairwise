class ItemsController < ApplicationController
  include Algorithms::Rank::Ewp
  include Algorithms::Rank::RSVD

  before_filter :force_xml

  # GET /items/1
  # ==== Return
  # Item by id.
  # ==== Options (params)
  # id<String>:: Converted to integer. ID of item.
  # rank_algorithm<String>:: Converted to integer. ID or name of rank algorithm.
  # If present score attribute is returned with score of this item according to
  # specified rank algorithm.  Default value is nil.
  # ==== Raises
  # PermissionError:: If item does not belong to user.
  def show
    @item = Item.find(params[:id], :conditions => { :user_id => current_user.id }, :include => [ :questions ])
    case parse_rank_algo_id(params[:rank_algorithm])
    when 1
      @score = lambda { |qid| @item.items_questions.first(:conditions => { :question_id => qid }).position }
    when 2
      @score = lambda do |qid|
        iq = i.items_questions.first(:conditions => { :question_id => qid })
        wins = iq.wins.to_if
        total = iq.wins + iq.losses
        total.zero? ? 0 : (100 * (wins/total)).round
      end
    when 3
      @score = lambda do |qid|
        ewp(@item, qid)
      end
    else
      @score = lambda { |qid| 0 }
    end
  end

  # POST /items/add
  # ==== Return
  # Added Item.
  # ==== Options (params)
  # active<String>:: Converted to boolean. If not nil item is activated.
  # tracking<String>:: String of data to be stored with item.
  # voter_id<String>:: Converted to Integer. Optional ID, if passed and
  # greater than zero items are linked to this voter.  Voter must be present
  # and be owner by the user.
  # ==== Post
  # Formatted XML of item to add and question to add item to.
  # ==== Raises
  # PermissionError:: If any questions do not belong to user.
  # PermissionError:: If any voters do not belong to user.
  def add
    return unless request.post?
    xml = LibXML::XML::Parser.parse(request.raw_post)
    active = !params[:active].nil?
    @items = xml.find("/items/item").inject([]) do |items, item|
      questions = item.find("questions/question").inject([]) do |arr, question|
        arr << current_user.questions.find(question.attributes["id"])
      end
      attributes = {:user_id => current_user.id, :data => item.find("data").first.content, :active => active}
      attributes.merge!(:tracking => params[:tracking]) if params[:tracking]
      if (voter_id = params[:voter_id].to_i) > 0
        raise PermissionError unless current_user.voters.find(voter_id)
        attributes.merge!(:voter_id => voter_id)
      end
      current_item = Item.create(attributes)
      current_item.questions << questions
      items << current_item
    end
  end

  # POST /items/delete
  # ==== Return
  # ID of item deleted and whether or not item was succesfully deleted.
  # ==== Options (params)
  # id<String>:: Converted to integer. ID of item.
  # ==== Raises
  # PermissionError:: If item does not belong to user.
  def delete
    return unless request.post?
    item = Item.find(@id = params[:id], :conditions => { :user_id => current_user.id })
    item.destroy
    @success = !Item.exists?(@id)
  end

  # GET /items/list
  # ==== Return
  # Array of items.
  # ==== Options (params)
  # limit<String>:: Converted to integer. Number of items to return.
  # offset<String>:: Converted to integer. Item to begin returning with.
  # order<String>:: Order to return items. If ASC items returned in ascending
  # order, otherwise items returned in descending order.
  # question_id<String>:: Converted to integer. Question to return items for.
  # data<String>:: Converted to boolean. If exists return data for items.
  # rank_algorithm<String>:: Name or ID of rank algorithm.  Default order is
  # by created at date.
  # ==== Raises
  # PermissionError:: If question does not belong to user.
  def list
    limit = params[:limit].to_i
    offset = params[:offset].to_i
    order = (params[:order] && params[:order].downcase == 'asc') ? 'ASC' : 'DESC'
    question_id = params[:question_id].to_i
    options = list_options(limit, offset, question_id)
    @data = !params[:data].nil?
    case parse_rank_algo_id(params[:rank_algorithm])
    when 1
      options[:order] = 'items_questions.position'
      if question_id > 0
        @score = lambda { |i| i.items_questions.first(:conditions => { :question_id => question_id }).position }
      else
        @score = lambda do |i|
          iqs = i.items_questions
          iqs.sumup(:position).to_f / iqs.length
        end
      end
    when 2
      # set score to percent wins after case
    when 3
      # unset limit and truncate after sort
      options[:limit] = nil if limit > 0
      @items = Item.all(options)
      stats = ewp_all(@items, question_id).inject({}) do |h, stat|
        h[stat.item_id.to_i] = stat_to_percent(stat)
        h
      end
      for item in @items
        item.score = stats[item.id] || 0
      end
      @items = @items.sort_by { |el| -el.score }
      @items = @items.first(limit) if limit > 0
      @score = lambda { |i| i.score }
    when 4
      res = row_list(question_id)
      if res
        res = res.inject({}) do |h, stat|
          h[stat[1].to_i] = stat[0]
          h
        end
        @items = Item.all(options)
        for item in @items
          item.score = res[item.id] || 0
        end
        @items = @items.sort_by { |el| -el.score }
        @score = lambda { |i| i.score }
      else
        @items = []
      end
    else
      options[:order] = 'items.created_at'
    end
    unless @score
      if question_id > 0
        @score = lambda do |i|
          iq = i.items_questions.first(:conditions => { :question_id => question_id })
          wins = iq.wins.to_f
          total = iq.wins + iq.losses
          total.zero? ? 0 : (100 * (wins/total)).round
        end
      else
        @score = lambda do |i|
          iqs = i.items_questions.all
          wins = iqs.sumup(:wins).to_f
          total = wins + iqs.sumup(:losses)
          total.zero? ? 0 : ((100 * (wins/total)) / iqs.length).round
        end
      end
    end
    unless @items
      options[:order] += " #{order}"
      @items = Item.all(options)
    end
  end

  # GET /items/suspend/1
  # ==== Return
  # Item in suspended state.
  # ==== Options (params)
  # id<String>:: Converted to integer. ID of item.
  # ==== Raises
  # PermissionError:: If item does not belong to user.
  def suspend
    update_item_state(params[:id], 0)
  end

  # GET /items/activate/1
  # ==== Return
  # Item in active state.
  # ==== Options (params)
  # id<String>:: Converted to integer. ID of item.
  # ==== Raises
  # PermissionError:: If item does not belong to user.
  def activate
    update_item_state(params[:id], 1)
  end

  private
    def update_item_state(id, state)
      @item = Item.find(id, :conditions => { :user_id => current_user.id })
      @item.update_attribute(:active, state)
      render :action => 'show'
      return
    end

    def parse_rank_algo_id(rank_algo)
      parse_model_name(RankAlgorithm, rank_algo)
    end

    def list_options(limit, offset, question_id)
      options = {
        :conditions => { :user_id => current_user.id },
        :include => [:items_questions],
        :order => 'items_questions.wins / (items_questions.wins + items_questions.losses)'
      }
      options[:limit] = limit if limit > 0
      options[:offset] = offset if offset > 0
      if question_id > 0
        raise PermissionError unless current_user.question_ids.include?(question_id)
        options[:joins] = "INNER JOIN items_questions ON items.id=items_questions.item_id AND items_questions.question_id=#{question_id}"
      end
      options
    end
end