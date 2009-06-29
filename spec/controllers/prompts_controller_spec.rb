require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptsController do
  fixtures :users, :questions, :prompt_algorithms, :items, :items_questions, :voters
  
  before(:each) do
    login_as('quentin')
  end

  describe "responding to GET create" do
    it "should not create prompts without question_id" do
      get :create
      response.status.should =~ /417/
    end

    it "should not create prompts if user doesn't own voter" do
      get :create, :question_id => 1, :voter_id => 2
      response.status.should =~ /417/
    end

    it "should not create prompts if user doesn't own question_id" do
      get :create, :question_id => 3, :voter_id => 1
      response.status.should =~ /417/
    end

    it "should create prompts for question and voter" do
      get :create, :question_id => 1, :voter_id => 1
      assigns[:prompt_item_ids].should_not == nil
      assigns[:prompt_item_ids].should_not == {}
      prompt = Prompt.find(assigns[:prompt_item_ids].keys.first)
      prompt.question.id.should == 1
      prompt.voter_id.should == 1
      prompt.reload.active.should == false
    end

    it "should create prompts without voter_id" do
      get :create, :question_id => 1
      Prompt.find(assigns[:prompt_item_ids].keys.first).voter_id.should == 0
    end

    it "should create N prompts for question" do
      get :create, :question_id => 1, :n => 4, :voter_id => 1
      assigns[:prompt_item_ids].should_not == nil
      assigns[:prompt_item_ids].keys.length.should == 4
      assigns[:prompt_item_ids].keys.each do |prompt|
        prompt = Prompt.find(prompt)
        prompt.question.id.should == 1
        prompt.voter.id.should == 1
        prompt.reload.active.should == false
      end
    end

    it 'should fail to create primed prompts if not enough stats' do
      get :create, :question_id => 1, :prime => 1
      Prompt.find(assigns[:prompt_item_ids].keys.first).prompt_algorithm_id.should == 2
    end

    it 'should create prompts for algo id' do
      get :create, :question_id => 1, :prompt_algorithm => 3
      Prompt.find(assigns[:prompt_item_ids].keys.first).prompt_algorithm_id.should == 4
    end

    it 'should not set data if not passed' do
      get :create, :question_id => 1
      assigns[:data].should == false
    end

    it 'should set data if passed' do
      get :create, :question_id => 1, :data => 1
      assigns[:data].should == true
    end

  end

  describe "responding to GET list" do
    fixtures :prompts, :items_prompts

    it "should get only users prompts" do
      get :list
      assigns[:prompts].each do |prompt|
        prompt.question.user_id.should == 1
      end
    end
    
    it "should get prompts for question" do
      get :list, :question_id => 1
      assigns[:prompts].each do |prompt|
        prompt.question.id.should == 1
      end
    end
    
    it "should get prompts with items" do
      items = Item.all(:limit => 2, :conditions => { :user_id => 1 })
      get :list, :item_id => items.map { |el| el.id }.join(',')
      assigns[:prompts].each do |prompt|
        (prompt.items & items).should_not be_empty
      end
    end
  end

  describe 'responding to GET view' do
    fixtures :prompts, :items_prompts, :items, :stats, :items_stats

    it 'should incr views for prompt' do
      prompt = Prompt.first
      stat = prompt.items.first.stats.first
      get :view, :id => prompt.id
      prompt.items.first.stats.first.views.should == stat.views + 1
    end
  end
end

def sorted(items)
  items.sort_by &:id
end