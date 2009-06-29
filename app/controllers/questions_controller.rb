class QuestionsController < ApplicationController
  before_filter :force_xml

  # GET /questions/1
  # ==== Return
  # Question and stats.
  # ==== Options (params)
  # id<String>:: Converted to integer. ID of question.
  # ==== Raises
  # PermissionError:: If question does not belong to user.
  def show
    @question = Question.first(:conditions => { :id => params[:id], :user_id => current_user.id })
    if @question
      @items_count = Item.count(
        :joins => "INNER JOIN items_questions ON (items_questions.item_id=items.id AND items_questions.question_id=#{@question.id})",
        :conditions => { :active => true }
      )
      @all_items_count = Item.count(:joins => "INNER JOIN items_questions ON (items_questions.item_id=items.id AND items_questions.question_id=#{@question.id})")
      @votes_count = Prompt.count(:joins => "INNER JOIN votes ON (votes.prompt_id=prompts.id)", :conditions => { :question_id => @question.id })
    end
  end

  # POST /questions/add
  # ==== Return
  # Added question.
  # ==== Post
  # Formatted XML of question to add.
  def add
    return unless request.post?
    xml = LibXML::XML::Parser.parse(request.raw_post)
    @questions = []
    xml.find("/questions/question").each do |question|
      @questions << Question.create(:user_id => current_user.id, :name => question.content)
    end
    GC.start
  end

  # POST /questions/delete
  # ==== Return
  # Question and deletion status.
  # ==== Options (params)
  # id<String>:: Converted to integer. ID of question.
  # ==== Raises
  # PermissionError:: If question does not belong to user.
  def delete
    return unless request.post?
    question = Question.find(@id = params[:id], :conditions => { :user_id => current_user.id })
    question.destroy
    @success = !Question.exists?(@id)
  end

  # GET /questions/list
  # ==== Return
  # Array of user questions.
  def list
    @questions = current_user.questions
    @items_count = Item.count(:conditions => { :user_id => current_user.id, :active => true })
    @all_items_count = Item.count(:conditions => { :user_id => current_user.id })
    @votes_count = Prompt.count(:joins => "INNER JOIN votes ON (votes.prompt_id=prompts.id)", :conditions => { :question_id => current_user.question_ids })
  end
end