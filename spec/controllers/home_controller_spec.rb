require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HomeController do
  fixtures :users, :items, :questions, :items_questions, :rank_algorithms, :voters, :features, :prompt_requests, :prompts, :stats, :items_stats

  before(:each) do
    @user_id = 1
    login_as('quentin')
  end

  describe 'delete' do
    describe 'get' do
      it 'should require post' do
        # get :delete
        # flash[:message].should == nil
      end

      it 'should redirect' do
        get :delete
        response.should be_redirect
      end
    end

    describe 'post' do
      before do
        @user = User.find(@user_id)
        @voters = @user.voters
        @items = @user.items
        @questions = @user.questions
        @features = @voters.map(&:features).flatten
        @prompt_requests = @questions.map(&:prompt_requests).flatten | @items.map(&:prompt_requests).flatten
        @stats = @items.map(&:stats).flatten
        @iqs = @questions.map(&:items_questions).flatten | @items.map(&:items_questions).flatten
        @prompts = @items.map(&:prompts).flatten
        @votes = @items.map(&:votes).flatten | @prompts.map(&:vote).flatten
        post :delete
      end

      it 'should set flash' do
        # flash[:message].should_not == nil
      end

      it 'should redirect' do
        response.should be_redirect
      end

#      it 'should delete voters' do
#        Voter.all(:conditions => { :id => @voters.map(&:id) }).empty?.should == true
#        @user.reload.voters.empty?.should == true
#      end

      it 'should delete items' do
        Item.all(:conditions => { :id => @items.map(&:id) }).empty?.should == true
        @user.reload.items.empty?.should == true
      end

      it 'should delete questions' do
        Question.all(:conditions => { :id => @questions.map(&:id) }).empty?.should == true
        @user.reload.questions.empty?.should == true
      end

#      it 'should delete features' do
#        Feature.all(:conditions => { :id => @features.map(&:id) }).empty?.should == true
#      end

      it 'should delete prompt_requests' do
        PromptRequest.all(:conditions => { :id => @prompt_requests.map(&:id) }).empty?.should == true
      end

      it 'should delete items questions' do
        ItemsQuestion.all(:conditions => { :id => @iqs.map(&:id) }).empty?.should == true
      end

      it 'should delete votes' do
        Vote.all(:conditions => { :id => @votes.map(&:id) }).empty?.should == true
      end

      it 'should delete prompts' do
        Prompt.all(:conditions => { :id => @prompts.map(&:id) }).empty?.should == true
      end
    end
  end
end