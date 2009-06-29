require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Stat do
  fixtures :items, :rank_algorithms

  before(:each) do
    @valid_attributes = {
      :question_id => 1,
    }
  end

  it 'should create a new instance given valid attributes' do
    Stat.create!(@valid_attributes)
  end

  describe 'view' do
    before do
      Stat.delete_all
      @ra = RankAlgorithm.find(Constants::Stat::DEFAULT_RANK_ALGO)
      @qid = 1
      @items = Item.all(:limit => 2)
      @stat = Stat.view(@qid, @items)
      @items |= @stat.items
    end

    describe 'if stat does not exist' do
      it 'should create a stat' do
        @stat.should_not == nil
      end

      it 'should create a stat with 0 votes' do
        @stat.votes.should == 0
      end

      it 'should create a stat with 1 view' do
        @stat.views.should == 1
      end

      it 'should create a stat for question' do
        @stat.question_id.should == @qid
      end

      it 'should create a stat for default rank algo' do
        @stat.rank_algorithm.should == @ra
      end

      it 'should create a stat with score based on default rank algo' do
        @stat.score.should == (-1 ** @ra.data.to_i).to_f
      end

      it 'should create a stat with items' do
        @stat.items.sort_by(&:id).should == @items.sort_by(&:id)
      end
    end

    describe 'if stat does exist' do
      before do
        @old_stat = @stat.dup
        @stat = Stat.view(@qid, @items)
      end

      it 'should return stat' do
        @stat.id.should == @old_stat.id
      end

      it 'should incr stat views' do
        @stat.views.should == @old_stat.views + 1
      end

      it 'should set views to >= votes' do
        (@stat.views >= @stat.votes).should == true
      end

      it 'should not increment votes' do
        @stat.votes.should == @old_stat.votes
      end

      it 'should update score' do
        n = 2 * @stat.votes - @stat.views
        @stat.score.should == ((n / n.abs) * (n.abs) ** @ra.data.to_i).to_f
      end
    end
  end

  describe 'vote' do
    before do
      Stat.delete_all
      @ra = RankAlgorithm.find(Constants::Stat::DEFAULT_RANK_ALGO)
      @qid = 1
      @items = Item.all(:limit => 2)
      @stat = Stat.vote(@qid, @items)
      @items |= @stat.items
    end

    describe 'if stat does not exist' do
      it 'should create a stat' do
        @stat.should_not == nil
      end

      it 'should create a stat with one vote' do
        @stat.votes.should == 1
      end

      it 'should create a stat with one view' do
        @stat.views.should == 1
      end

      it 'should create a stat for question' do
        @stat.question_id.should == @qid
      end

      it 'should create a stat for default rank algo' do
        @stat.rank_algorithm.should == @ra
      end

      it 'should create a stat with score based on default rank algo' do
        @stat.score.should == 1 ** @ra.data.to_i
      end

      it 'should create a stat with items' do
        @stat.items.sort_by(&:id).should == @items.sort_by(&:id)
      end

      describe 'items stats' do
        it 'should not update on skip' do
          saved_is = @items.map do |item|
            ItemsStat.first(:conditions => { :stat_id => @stat.id, :item_id => item.id })
          end
          Stat.vote(@qid, @items)
          saved_is.each do |is|
            is.wins.should == is.reload.wins
            is.losses.should == is.reload.losses
          end
        end

        it 'should incr wins' do
          saved_is = @items.map do |item|
            ItemsStat.first(:conditions => { :stat_id => @stat.id, :item_id => item.id })
          end
          Stat.vote(@qid, @items, [@items.first])
          saved_is.each do |is|
            wins = is.item_id == @items.first.id ? is.wins + 1 : is.wins
            is.reload.wins.should == wins
          end
        end

        it 'should incr losers' do
          saved_is = @items.map do |item|
            ItemsStat.first(:conditions => { :stat_id => @stat.id, :item_id => item.id })
          end
          Stat.vote(@qid, @items, [@items.first])
          saved_is.each do |is|
            losses = is.item_id == @items.first.id ? is.losses : is.losses + 1
            is.reload.losses.should == losses
          end
        end
      end
    end

    describe 'if stat does exist' do
      before do
        @old_stat = @stat.dup
        @stat = Stat.vote(@qid, @items)
      end

      it 'should return stat' do
        @stat.id.should == @old_stat.id
      end

      it 'should incr stat votes' do
        @stat.votes.should == @old_stat.votes + 1
      end

      it 'should set views to >= votes' do
        (@stat.views >= @stat.votes).should == true
      end

      it 'should update score' do
        @stat.score.should == (2*@stat.votes - @stat.views) ** @ra.data.to_i
      end

      it 'should have only one stat for pair of items' do
        @stat = Stat.vote(@qid, @items)
        old_lengths = @items.map { |item| item.stats.length }
        1.upto(10) do
          @stat = Stat.vote(@qid, @items)
        end
        for item in @items
          item.stats.length.should == old_lengths.shift
        end
      end
    end
  end
end
