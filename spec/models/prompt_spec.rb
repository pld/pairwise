require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Prompt do
  before(:each) do
    @valid_attributes = {
      :question_id => "1",
      :prompt_algorithm_id => "1",
      :voter_id => "1"
    }
  end

  it "should create a new instance given valid attributes" do
    Prompt.create!(@valid_attributes)
  end

  # describe 'find or create' do
  #   before do
  #     @prompt = mock_model(Prompt)
  #   end
  # 
  #   it 'should find prompts for args' do
  #     Prompt.should_receive(:find_for).with({}, nil, 1).and_return(@prompt)
  #     @prompt.should_receive(:length).and_return(1)
  #     @prompt.should_receive(:map).and_return([1])
  #     @prompt.should_receive(:empty?).and_return(false)
  #     Prompt.find_or_create({}, nil, 1).should == @prompt
  #   end
  # 
  #   it 'should deactivate prompts' do
  #     Prompt.should_receive(:find_for).with({}, nil, 1).and_return(@prompt)
  #     @prompt.should_receive(:length).and_return(1)
  #     @prompt.should_receive(:empty?).and_return(false)
  #     @prompt.should_receive(:map).and_return([1])
  #     Prompt.should_receive(:update_all).with("active=0", "prompts.id IN (1)")
  #     Prompt.find_or_create({}, nil, 1).should == @prompt
  #   end
  # 
  #   it 'should not deactive prompts if prompts are empty' do
  #     Prompt.should_receive(:find_for).with({}, nil, 1).and_return(@prompt)
  #     @prompt.should_receive(:length).and_return(1)
  #     @prompt.should_receive(:empty?).and_return(true)
  #     Prompt.should_not_receive(:update_all)
  #     @prompt.should_not_receive(:map)
  #     Prompt.find_or_create({}, nil, 1).should == @prompt
  #   end
  # 
  #   it 'should request missing prompts' do
  #     Prompt.should_receive(:find_for).with({}, nil, 2).and_return([@prompt])
  #     Prompt.should_receive(:request).with({:count => 1}, nil).and_return([@prompt])
  #     @prompt.should_receive(:question_id).twice.and_return([1])
  #     @prompt.should_receive(:items).twice.and_return([])
  #     Prompt.find_or_create({}, nil, 2).should == Array.new(2, @prompt)
  #   end
  # 
  #   it 'should create stats for items in prompts' do
  #     items = Array.new(2, mock_model(Item))
  #     Stat.should_receive(:view).with(1, items).twice
  #     Prompt.should_receive(:find_for).with({}, nil, 2).and_return([@prompt])
  #     Prompt.should_receive(:request).with({:count => 1}, nil).and_return([@prompt])
  #     @prompt.should_receive(:question_id).twice.and_return(1)
  #     @prompt.should_receive(:items).twice.and_return(items)
  #     Prompt.find_or_create({}, nil, 2).should == Array.new(2, @prompt)
  #   end
  # end

  describe 'prompt request algo' do
    fixtures :items, :questions, :items_questions, :rank_algorithms

    before do
      @question = Question.first
      @voter_id = 0
      @num = 1
      @items = Item.all(        {
        :joins => "INNER JOIN items_questions ON (items_questions.question_id=#{@question.id} AND items_questions.item_id=items.id)",
        :conditions => { :active => true },
        :group => "items.id"
      })
      srand 1234
      @count = 10
      items = @items.dup
      @prompt_items = @count.times.inject([]) do |arr, i|
        items = @items.dup if items.length < 2 # ensure we still have items
        el = items.delete_at(rand(items.length))
        arr << [el, items.delete_at(rand(items.length))]
      end
      Prompt.delete_all
      PromptRequest.delete_all
      Stat.delete_all
      ActiveRecord::Base.connection.execute("DELETE FROM `items_stats`")
      srand 1234
    end

    it 'should return prompt' do
      Prompt.fetch(@question.id, @voter_id, @num, false).empty?.should == false
    end

    it "should return same as seeded prompts if count < #{@count}" do
      pids = @prompt_items[0].map(&:id).sort
      (Prompt.find((Prompt.fetch(@question.id, @voter_id, @num, false).first.first)).items.map(&:id) | pids).sort.should == pids
    end

    it 'should set prompts inactive' do
      Prompt.find(Prompt.fetch(@question.id, @voter_id, @num, false).first.first).reload.active.should == false
    end

    it 'should set view for prompt items' do
      Prompt.find(Prompt.fetch(@question.id, @voter_id, @num, false).first.first).items.map{ |i| i.reload.stats }.flatten.each do |stat|
        stat.views.should == 1
      end
    end

    it 'should return standard random prompt prime and no stats' do
      prompts = Prompt.find(Prompt.fetch(@question.id, @voter_id, @count, true).keys)
      @prompt_items.each do |items|
        pids = items.map(&:id).sort
        (prompts.shift.items.map(&:id).sort | pids).sort.should == pids
      end
    end

    describe 'with stats' do
      before do
        Stat.delete_all
        @count = 10
        Prompt.fetch(@question.id, @voter_id, @count, false).keys.each do |prompt_id|
          prompt = Prompt.find(prompt_id)
          if (prompt_id % 2).zero?
            2.times { Stat.vote(prompt.question_id, prompt.items) }
          else
            Stat.view(prompt.question_id, prompt.items)
          end
        end
        srand 1234
        stats = Stat.find_all_by_question_id(@question.id, :order => 'score')
        pos = stats.map(&:score).min.abs + 1
        norm = cur = 0
        # the probablity of choose the items in a stat is stat.score / sum(stats.scores)
        stats = stats.inject({}) do |hash, stat|
          norm += adj = stat.score + pos
          hash[stat] = [cur, cur += adj]
          hash
        end
        @stat_items = @count.times.inject([]) do |arr, i|
          r = rand(norm)
          arr << stats.detect { |stat| stat[1][0] <= r && r < stat[1][1] }[0].items
        end
        srand 1234
      end

      it 'should return standard random prompt prime false' do
        prompts = Prompt.find(Prompt.fetch(@question.id, @voter_id, @count, false).keys)
        @prompt_items.first(@count).each do |items|
          pids = items.map(&:id).sort
          (prompts.shift.items.map(&:id).sort | pids).sort.should == pids
        end
      end

      it 'should set rand algo id if prime false' do
        Prompt.find(Prompt.fetch(@question.id, @voter_id, @count, false).keys).each do |prompt|
          prompt.prompt_algorithm_id.should == 2
        end
      end


      it 'should base prompts on stats if algo ID passed and stats' do
        prompts = Prompt.find(Prompt.fetch(@question.id, @voter_id, @count, 2).keys)
        @stat_items.each do |items|
          pids = items.map(&:id).sort
          (prompts.shift.items.map(&:id) | pids).sort.should == pids
        end
      end

      it 'should set prompt algo id if algo ID passed and stats' do
        Prompt.find(Prompt.fetch(@question.id, @voter_id, @count, 2).keys).each do |prompt|
          prompt.prompt_algorithm_id.should == 3
        end
      end
    end
  end
end
