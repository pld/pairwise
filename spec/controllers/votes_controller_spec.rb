require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VotesController do
  fixtures :users, :questions, :prompts, :items_prompts, :prompt_algorithms, :items, :items_questions, :voters, :rank_algorithms
  
  before(:each) do
    login_as('quentin')
  end

  describe "responding to GET add" do
    before do
      Vote.delete_all
      Stat.delete_all
      ActiveRecord::Base.connection.execute("DELETE FROM `items_stats`")
      for iq in ItemsQuestion.all
        iq.update_attributes({:ratings => 0, :wins => 0, :losses => 0})
      end
    end

    it "should require prompt_id" do
      get :add
      response.status.should =~ /417/
    end

    it "should require prompt_id with skip" do
      get :add, :skip => 1
      response.status.should =~ /417/
    end

    it "should require prompt_id with item" do
      get :add, :item_id => 1
      response.status.should =~ /417/
    end

    it "should require item_id in prompt" do
      get :add, :prompt_id => 1, :item_id => 3, :voter_id => 1
      response.status.should =~ /417/
    end

    it "should require user voter" do
      get :add, :prompt_id => 1, :item_id => 1, :voter_id => 2
      response.status.should =~ /403/
    end

    it "should add vote" do
      get :add, :prompt_id => 1, :item_id => 1, :voter_id => 1
      assigns[:vote].items.first.id.should == 1
      assigns[:vote].prompt_id.should == 1
    end

    it 'should allow skip' do
      get :add, :prompt_id => 1, :voter_id => 1, :skip => 1
      assigns[:vote].prompt_id.should == 1
      assigns[:vote].items.should be_empty
    end

    it 'should allow 0 voter id' do
      get :add, :prompt_id => 1, :item_id => 1, :voter_id => 0
      assigns[:vote].items.first.id.should == 1
      assigns[:vote].prompt_id.should == 1
    end

    it "should add vote for multiple items" do
      get :add, :prompt_id => 1, :item_id => '1,2', :voter_id => 0
      assigns[:vote].voter_id.should == 0
    end

    it "should add vote with response time" do
      # 100 == 1s
      get :add, :prompt_id => 1, :item_id => 1, :voter_id => 1, :response_time => 100
      assigns[:vote].response_time.should == 100
    end

    it 'should increment ratings' do
      items = Prompt.find(1).items
      get :add, :prompt_id => 1, :voter_id => 1, :skip => 1
      prompt = Prompt.find(1)
      prompt.items.each do |item|
        item.iq(prompt.question_id).ratings.should == items.shift.iq(prompt.question_id).ratings
      end
    end

    it 'should keep stored ratings aligned with db records' do
      for prompt in Prompt.all do
        get :add, :prompt_id => prompt.id, :voter_id => 1, :skip => 1
      end
      for prompt in Prompt.all do
        prompt.items.each do |item|
          item.iq(prompt.question_id).ratings.should == Vote.count(
            :joins => "INNER JOIN prompts ON (votes.prompt_id=prompts.id) INNER JOIN items_prompts ON (prompts.id=items_prompts.prompt_id AND items_prompts.item_id=#{item.id})",
            :conditions => { 'prompts.question_id' => prompt.question_id }
          )
        end
      end
    end

    it 'should increment wins of winner' do
      prompt = Prompt.find(1)
      wins = Item.find(1).iq(prompt.question_id).wins
      get :add, :prompt_id => 1, :item_id => 1, :voter_id => 1
      Item.find(1).iq(prompt.question_id).wins.should == wins + 1
    end

    it 'should keep stored wins aligned with db records' do
      i = 0
      for prompt in Prompt.all do
        if ((i += 1) % 2).zero?
          get :add, :prompt_id => prompt.id, :voter_id => 1, :item_id => 1
        else
          get :add, :prompt_id => prompt.id, :voter_id => 1, :skip => 1
        end
      end
      item = Item.find(1)
      item.iq(1).wins.should == Vote.count(
        :joins => "INNER JOIN prompts ON (votes.prompt_id=prompts.id) INNER JOIN items_votes ON (votes.id=items_votes.vote_id AND items_votes.item_id=#{item.id})",
        :conditions => { 'prompts.question_id' => 1 }
      )
    end

    it 'should keep store losses aligned with db losses' do
      i = 0
      for prompt in Prompt.all do
        if ((i += 1) % 2).zero?
          get :add, :prompt_id => prompt.id, :voter_id => 1, :item_id => 1
        else
          get :add, :prompt_id => prompt.id, :voter_id => 1, :skip => 1
        end
      end
      for item in Item.all
        item.iq(prompt.question_id).losses.should == Prompt.count(
          :joins => "INNER JOIN items_prompts ON (prompts.id=items_prompts.prompt_id AND items_prompts.item_id=#{item.id}) INNER JOIN votes ON (votes.prompt_id=prompts.id) INNER JOIN items_votes ON (votes.id=items_votes.vote_id AND items_votes.item_id!=items_prompts.item_id)",
          :conditions => { 'prompts.question_id' => prompt.question_id }
        )
      end
    end

    it 'should have total ratings equal to number vote records * 2' do
      i = 0
      for prompt in Prompt.all do
        if ((i += 1) % 2).zero?
          get :add, :prompt_id => prompt.id, :voter_id => 1, :item_id => 1
        else
          get :add, :prompt_id => prompt.id, :voter_id => 1, :skip => 1
        end
      end
      ItemsQuestion.all.sumup(:ratings).should == Vote.count * 2
    end

    it 'should have total wins equal to number vote records with items * 2' do
      i = 0
      for prompt in Prompt.all do
        if ((i += 1) % 2).zero?
          get :add, :prompt_id => prompt.id, :voter_id => 1, :item_id => 1
        else
          get :add, :prompt_id => prompt.id, :voter_id => 1, :skip => 1
        end
      end
      ItemsQuestion.all.sumup(:wins).should == Prompt.all(
        :select => "items_votes.item_id, prompts.question_id, COUNT(*) AS count",
        :joins => "INNER JOIN votes ON (votes.prompt_id=prompts.id) INNER JOIN items_votes ON (votes.id=items_votes.vote_id)",
        :group => "items_votes.item_id, prompts.question_id"
      ).sumup(:count)
    end

    it 'should have total skips equal to number vote records without items * 2' do
      i = 0
      for prompt in Prompt.all do
        if ((i += 1) % 2).zero?
          get :add, :prompt_id => prompt.id, :voter_id => 1, :item_id => 1
        else
          get :add, :prompt_id => prompt.id, :voter_id => 1, :skip => 1
        end
      end
      ItemsQuestion.all.inject(0) do |sum, iq|
        sum += iq.ratings - iq.wins - iq.losses
      end.should == Prompt.all(
        :select => "items_votes.item_id, prompts.question_id, COUNT(*) AS count",
        :joins => "INNER JOIN votes ON (votes.prompt_id=prompts.id) LEFT OUTER JOIN items_votes ON (votes.id=items_votes.vote_id)",
        :conditions => "items_votes.item_id IS NULL",
        :group => "items_votes.item_id, prompts.question_id"
      ).sumup(:count) * 2
    end

    it 'should adjust elo with winner' do
      prompt = Prompt.find(1)
      old_first = prompt.items.first.iq(prompt.question_id).position
      old_last = prompt.items.last.iq(prompt.question_id).position
      get :add, :prompt_id => 1, :item_id => 1, :voter_id => 1
      (prompt.items.first.iq(prompt.question_id).position > old_first).should == true
      (prompt.items.last.iq(prompt.question_id).position < old_last).should == true
    end

    it 'should adjust elo with skip' do
      prompt = Prompt.find(1)
      old_first = prompt.items.first.iq(prompt.question_id).position
      old_last = prompt.items.last.iq(prompt.question_id).position
      get :add, :prompt_id => 1, :skip => 1, :voter_id => 1
      prompt.items.first.iq(prompt.question_id).position.should == old_first
      prompt.items.last.iq(prompt.question_id).position.should == old_last - 1
    end

    it 'should create stat for items' do
      get :add, :prompt_id => 1, :skip => 1, :voter_id => 1
      Prompt.find(1).items.each do |item|
        item.stats.empty?.should == false
      end
    end

    it 'should set stats for items' do
      get :add, :prompt_id => 1, :skip => 1, :voter_id => 1
      Prompt.find(1).items.each do |item|
        item.stats.each { |stat| stat.votes.should == 1 }
      end
    end

    it 'should add tracking for vote' do
      tracking = 'DATA STRING'
      get :add, :prompt_id => 1, :skip => 1, :voter_id => 1, :tracking => tracking
      Vote.last.tracking.should == tracking
    end

    describe 'items stats' do
      before do
        prompt = Prompt.find(1)
        @items = prompt.items
        Stat.vote(prompt.question_id, @items, [])
        stat = Stat.for_items(prompt.question_id, @items)
        @saved_is = @items.map do |item|
          ItemsStat.first(:conditions => { :stat_id => stat.id, :item_id => item.id })
        end
      end
      it 'should not incr on skip' do
        get :add, :prompt_id => 1, :skip => 1, :voter_id => 1
        @saved_is.each do |is|
          is.wins.should == is.reload.wins
          is.losses.should == is.reload.losses
        end
      end

      it 'should incr item stats wins for winners on win' do
        get :add, :prompt_id => 1, :item_id => @items.first.id, :voter_id => 1
        @saved_is.each do |is|
          wins = is.item_id == @items.first.id ? is.wins + 1 : is.wins
          is.reload.wins.should == wins
        end
      end

      it 'should incr item stats losses for losers on win' do
        get :add, :prompt_id => 1, :item_id => @items.first.id, :voter_id => 1
        @saved_is.each do |is|
          losses = is.item_id == @items.first.id ? is.losses : is.losses + 1
          is.reload.losses.should == losses
        end
      end

    end
  end
  
  describe "responding to GET list" do
    it "should only get votes for user" do
      get :list
      assigns[:votes].each do |vote|
        vote.prompt.question.user_id.should == 1
      end
    end
  end
end