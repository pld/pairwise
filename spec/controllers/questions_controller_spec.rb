require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsController do
  fixtures :users, :questions, :items, :votes, :prompts

  before(:each) do
    login_as('quentin')
  end

  describe "responding to GET list" do
    it "should get only users questions" do
      get :list
      assigns[:questions].each do |q|
        q.user_id.should == 1
      end
    end

    it 'should get items for question' do
      get :list
      assigns[:items_count].should == User.find(1).items.all(:conditions => { :active => true }).length
    end

    it 'should get all items for question' do
      get :list
      assigns[:all_items_count].should == User.find(1).items.length
    end

    it 'should get all votes for question' do
      get :list
      assigns[:votes_count].should == Vote.count(:conditions => { 'questions.user_id' => 1 }, :include => { :prompt => :question })
    end
  end

  describe "responding to POST add" do
    it "should add questions" do
      xml_post :add, "questions"
      question = Question.find_by_name('new')
      question2 = Question.find_by_name('new2')
      assigns[:questions].should == [question, question2]
    end
  end

  describe 'responding to GET show' do
    it 'should expose question' do
      get :show, :id => 1
      assigns[:question].should == Question.find(1)
    end


    it 'should not expose non-user items' do
      get :show, :id => 4
      assigns[:question].should == nil
    end

    it 'should get items for question' do
      get :show, :id => 1
      assigns[:items_count].should == Question.find(1).items.all(:conditions => { :active => true }).length
    end

    it 'should get all items for question' do
      get :show, :id => 1
      assigns[:all_items_count].should == Question.find(1).items.length
    end

    it 'should get all votes for question' do
      get :show, :id => 1
      assigns[:votes_count].should == Vote.count(:conditions => { 'prompts.question_id' => 1 }, :include => :prompt)
    end
  end

  describe 'responding to POST delete' do
    fixtures :items, :items_questions, :prompts, :votes
    before do
      @question = Question.find(1)
      @iqs = @question.items_questions
      @prompts = @question.prompts
      @votes = @prompts.map(&:vote).flatten.compact
      @prs = @question.prompt_requests
    end

    it 'should return if not post' do
      get :delete
      assigns[:success].should == nil
    end

    it 'should delete question' do
      post :delete, :id => @question.id
      Question.exists?(@question.id).should == false
    end

    it 'should delete item questions' do
      post :delete, :id => @question.id
      ItemsQuestion.all(:conditions => { :id => @iqs.map(&:id) }).empty?.should == true
    end

    it 'should delete prompt requests' do
      post :delete, :id => @question.id
      PromptRequest.all(:conditions => { :id => @prs.map(&:id) }).empty?.should == true
    end

    it 'should delete prompts' do
      post :delete, :id => @question.id
      Prompt.all(:conditions => { :id => @prompts.map(&:id) }).empty?.should == true
    end

    it 'should delete votes' do
      post :delete, :id => @question.id
      Vote.all(:conditions => { :id => @votes.map(&:id) }).empty?.should == true
    end

    it 'should assign id' do
      post :delete, :id => @question.id
      assigns[:id].should == @question.id.to_s
    end

    it 'should assign success true' do
      post :delete, :id => @question.id
      assigns[:success].should == true
    end

    it 'should assign success false' do
      post :delete, :id => @question.id
      post :delete, :id => @question.id
      response.status.should =~ /400/
    end
  end
end
