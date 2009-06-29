require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ItemsController do
  include Algorithms::Rank::Elo
  fixtures :users, :items, :questions, :items_questions, :rank_algorithms, :votes, :items_votes, :voters

  def mock_item(stubs={})
    @mock_item ||= mock_model(Item, stubs)
  end

  before(:each) do
    @user_id = 1
    login_as('quentin')
  end

  def all_user_items
    Item.find(:all, :conditions => { :user_id => @user_id }, :order => 'created_at asc')
  end

  def items_by_rank_algo(user_id, order, question_id = 0, limit = 0)
    Algorithms::Rank::Elo.score(user_id, order, question_id, limit).first
  end

  describe "responding to GET list" do
    it "should expose all user items as @items" do
      get :list
      assigns[:items].should_not == Item.find(:all)
      assigns[:items].each do |item|
        item.user_id.should == @user_id
      end
    end

    it "should limit items to n" do
      get :list, :limit => 2
      assigns[:items].should == Item.find(:all, :conditions => { :user_id => @user_id }, :order => "items.created_at desc")[0,2]
    end

    it "should order items by order" do
      get :list, :order => 'asc'
      assigns[:items].should == all_user_items
    end

    it "should order items by order and limit" do
      get :list, :order => 'asc', :limit => 2
      assigns[:items].should == all_user_items[0,2]
    end

    it "should get items for question" do
      get :list, :question_id => 1
      assigns[:items].each do |item|
        item.questions.first.id.should == 1
      end
    end

    it "should order by rank algo passing id" do
      get :list, :rank_algorithm => 1
      assigns[:items].should == Item.all(
        :conditions => { :user_id => current_user.id },
        :order => 'items_questions.position desc',
        :include => 'items_questions'
      )
    end

    it "should order by rank algo passing name" do
      get :list, :rank_algorithm => 'elo'
      assigns[:items].should == Item.all(
        :conditions => { :user_id => current_user.id },
        :order => 'items_questions.position desc',
        :include => 'items_questions'
      )
    end

    it 'should order by rank algo asc' do
      get :list, :rank_algorithm => 1, :order => 'ASC'
      assigns[:items].should == Item.all(
        :conditions => { :user_id => current_user.id },
        :order => 'items_questions.position asc',
        :include => 'items_questions'
      )
    end

    it 'should order by rank algo ewp and limit' do
      get :list, :rank_algorithm => 'ewp', :order => 'ASC', :limit => 5
      assigns[:items].length.should == 5
    end

    it 'should order by all rank algos' do
      for algo in RankAlgorithm.all
        get :list, :rank_algorithm => algo.id
        assigns[:items].should_not == nil
      end
    end

    it 'should order by all rank algos with question_id' do
      for algo in RankAlgorithm.all
        get :list, :rank_algorithm => algo.id, :question_id => 1
        assigns[:items].should_not == nil
      end
    end
  end

  describe "responding to POST add" do
    it "should return unless post" do
      get :add
      assigns[:items].should == nil
    end
    
    it "should create items" do
      xml_post :add, 'items_good'
      item = Item.find_by_data('new')
      item2 = Item.find_by_data('new2')
      assigns[:items].should == [ item, item2 ]
      assigns[:items].first.questions.first.id.should == 1
      assigns[:items].first.questions.last.id.should == 2
    end

    it "should store tracking with items if passed" do
      track = "track"
      xml_post :add, 'items_good', :tracking => track
      for item in assigns[:items]
        item.tracking.should == track
      end
    end

    it "should store voter with items if passed" do
      voter_id = 1
      xml_post :add, 'items_good', :voter_id => voter_id
      for item in assigns[:items]
        item.voter_id.should == voter_id
      end
    end

    it "should error if voter not owner by user" do
      xml_post :add, 'items_good', :voter_id => 2
      response.status.should =~ /400/
    end
    
    it "should error if invalid question_id" do
      xml_post :add, 'items_bad'
      response.status.should =~ /400/
    end
  end
  
  describe "responding to GET activate" do
    it "should activate" do
      get :activate, :id => 1
      assigns[:item].should == Item.find(1)
      assigns[:item].active.should == true
    end
    
    it "should not activate not owned items" do
      get :activate, :id => 11
      response.status.should =~ /400/
    end
  end

  describe "responding to GET suspend" do
    it "should suspend" do
      get :suspend, :id => 1
      assigns[:item].should == Item.find(1)
      assigns[:item].active.should == false
    end
    
    it "should not suspend not owned items" do
      get :suspend, :id => 11
      response.status.should =~ /400/
    end
  end

  describe 'responding to GET show' do
    it 'should expose item' do
      get :show, :id => 1
      assigns[:item].should == Item.find(1)
    end

    it 'should not expose non-user items' do
      get :show, :id => 11
      assigns[:item].should == nil
    end
  end

  describe 'responding to POST delete' do
    fixtures :prompt_requests, :stats, :items_stats

    before do
      @item = Item.first(:conditions => { :user_id => @user_id })
      @iqs = @item.items_questions
      @prompts = @item.prompts
      @stats = @item.stats
      @votes = @item.votes
      @prs = @item.prompt_requests
    end

    it 'should return if not post' do
      get :delete
      assigns[:success].should == nil
    end

    it 'should delete item' do
      post :delete, :id => @item.id
      Item.exists?(@item.id).should == false
    end

    it 'should delete item questions' do
      post :delete, :id => @item.id
      ItemsQuestion.all(:conditions => { :id => @iqs.map(&:id) }).empty?.should == true
    end

    it 'should delete prompts' do
      post :delete, :id => @item.id
      Prompt.all(:conditions => { :id => @prompts.map(&:id) }).empty?.should == true
    end

    it 'should delete votes' do
      post :delete, :id => @item.id
      Vote.all(:conditions => { :id => @votes.map(&:id) }).empty?.should == true
    end

    it 'should delete stats' do
      post :delete, :id => @item.id
      Stat.all(:conditions => { :id => @stats.map(&:id) }).empty?.should == true
    end

    it 'should delete prompt requests' do
      post :delete, :id => @item.id
      PromptRequest.all(:conditions => { :id => @prs.map(&:id) }).empty?.should == true
    end


    it 'should assign id' do
      post :delete, :id => @item.id
      assigns[:id].should == @item.id.to_s
    end

    it 'should assign success true' do
      post :delete, :id => @item.id
      assigns[:success].should == true
    end

    it 'should assign success false' do
      post :delete, :id => @item.id
      post :delete, :id => @item.id
      response.status.should =~ /400/
    end
  end
end