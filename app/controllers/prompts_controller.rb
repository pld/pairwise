class PromptsController < ApplicationController
  before_filter :force_xml

  # GET /prompts/1
  # ==== Return
  # Prompt.
  # ==== Options (params)
  # id<String>:: Converted to integer. ID of prompt.
  # ==== Raises
  # PermissionError:: If prompt does not belong to user.
  def show
    @prompt = Prompt.find(params[:id])
    raise PermissionError unless current_user.question_ids.include?(@prompt.question_id)
  end

  # GET /prompts/view/1
  # ==== Return
  # Nothing.
  # ==== Options (params)
  # id<String>:: Converted to integer. ID of prompt to register view for.
  # ==== Raises
  # PermissionError:: If prompt does not belong to user.
  def view
    prompt = Prompt.find(params[:id])
    raise PermissionError unless current_user.question_ids.include?(prompt.question_id)
    Stat.view(prompt.question_id, prompt.items)
    head :ok
  end

  # GET /prompts/list
  # ==== Return
  # Array of length n. Prompts matching parameters
  # ==== Options (params)
  # question_id<String>:: Converted to integer. Must be greater than 0 and
  # belong to the current user.  Must belong to user.
  # item_ids<String>:: Comma seperated list of items to include. May only
  # include commas and digits.  Must belong to user.  Optional value.
  # data<String>:: Flag for whether to include item data.  Data included
  # if value is not nil.
  # ==== Raises
  # PermissionError:: If question or any item doesn't belong to current user.
  def list
    question_id = params[:question_id].to_i
    item_ids = params[:item_id]
    @data = !params[:data].nil?
    item_ids = valid_item_ids(item_ids)
    options =  { :include => :items, :conditions => {} }
    if question_id > 0
      options[:conditions].merge!('prompts.question_id' => question_id)
      raise PermissionError unless current_user.question_ids.include?(question_id)
      unless item_ids.empty?
        raise PermissionError unless (item_ids - current_user.item_ids).empty?
        options[:conditions].merge!({ 'items.id' => item_ids })
      end
      @prompts = Prompt.all(options)
    else
      @prompts = []
    end
  end

  # GET /prompts/create
  # ==== Return
  # Array of length n. Prompts created for the question and voter. Returns a
  # maximum of Constants::MAX_BATCH_PROMPTS at a time.
  # ==== Options (params)
  # question_id<String>:: Converted to integer. Must be greater than 0 and belong to the current user.
  # voter_id<String>:: Converted to integer. Must be 0 or belong to the current user.
  # n<String>:: Converted to integer. Set to 1 if less than 1. Set to MAX_BATCH_PROMPTS if greater
  # than MAX_BATCH_PROMPTS.
  # item_id<String>:: Nil or comma seperated list of items to include in the prompt.
  # be returned.
  # prime<String>:: If passed the probability of a prompt being generated will
  # be proportional to the number of times this prompt has been voted on in the
  # past (note: you must submit prompt view requests on prompt viewing for this
  # proportion to be accurate).
  # data<String>:: If passed the item is returned with its data.
  # prompt_algorithm<String>:: Converted to integer. If passed the specified
  # prompt algorithm will be used to generate the prompt. Can be an ID or name
  # of prompt algorithm.
  # ==== Raises
  # ArgumentError:: If question less than 1 or doesnt belong to current user or if voter greater than 0
  # and doesn't belong to current user.
  def create
    @question_id = params[:question_id].to_i
    voter_id = params[:voter_id].to_i
    num = params[:n].to_i
    prompt_algorithm_id = parse_prompt_algo_id(params[:prompt_algorithm], params[:prime])
    @data = !params[:data].nil?
    if num < 1
      num = 1
    elsif num > Constants::MAX_BATCH_PROMPTS
      num = Constants::MAX_BATCH_PROMPTS
    end
    raise ArgumentError unless current_user.questions.exists?(@question_id) && (voter_id < 1 || current_user.voters.exists?(voter_id))
    @prompt_item_ids = Prompt.fetch(@question_id, voter_id, num, prompt_algorithm_id)
    @algorithm_id = prompt_algorithm_id || 2
    raise ArgumentError if @prompt_item_ids.keys.empty?
  end

  private
    def parse_prompt_algo_id(algo, prime)
      if prime.to_i > 0
        Constants::DEFAULT_PROMPT_ALGO
      else
        parse_model_name(PromptAlgorithm, algo)
      end
    end

    # If non "," or digit is passed as an "item_id" param all item params are ignored
    def valid_item_ids(item_ids) #:doc:
      (item_ids && !item_ids.empty? && item_ids.gsub(/,|\d/, '').empty?) ? item_ids.split(',').map(&:to_i) : []
    end
end