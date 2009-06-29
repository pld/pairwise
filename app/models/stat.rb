class Stat < ActiveRecord::Base
  belongs_to :question
  belongs_to :rank_algorithm
  has_many :items_stats
  has_many :items, :through => :items_stats

  validates_presence_of :question_id
  validates_presence_of :views
  validates_presence_of :votes
  validates_presence_of :score

  class << self
    include Constants::Stat

    # Update view for or create stat for items
    def view(question_id, items)
      return if items.empty? || !RankAlgorithm.exists?(DEFAULT_RANK_ALGO)
      stat = for_items(question_id, items)
      if stat
        views = stat.views + 1
        stat.update_attributes({ :views => views, :score => score(stat.rank_algorithm.data.to_i, stat.votes, views) })
      else
        stat = create(default(question_id))
        stat.items << items
      end
      stat
    end

    # Update vote for or create stat for items. Assume items are linked to the
    # passed question id as they should be.
    def vote(question_id, items, winners = [])
      return if items.empty? || !RankAlgorithm.exists?(DEFAULT_RANK_ALGO)
      stat = for_items(question_id, items)
      if stat
        votes = stat.votes + 1
        # if fewer views thatn votes a view wasn't counted, set to number of votes
        views = stat.views < votes ? votes : stat.views
        options = { :votes => votes, :score => score(stat.rank_algorithm.data.to_i, votes, views) }
        options.merge!(:views => views) if views != stat.views
        stat.update_attributes(options)
      else
        stat = create(default(question_id, 1))
        stat.items << items
      end
      for winner in winners
        ItemsStat.first(:conditions => { :stat_id => stat.id, :item_id => winner.id }).increment!(:wins)
      end
      for loser in (items - winners)
        ItemsStat.first(:conditions => { :stat_id => stat.id, :item_id => loser.id }).increment!(:losses)
      end
      stat
    end

    # Get stats for specific items.  Any set of items should have one stat.
    # Merge together multiple stats.
    def for_items(question_id, items)
      return if items.empty?
      joins = items.inject('') do |str, i|
        str += "INNER JOIN items_stats AS items_stats_#{i.id} ON (items_stats_#{i.id}.stat_id=stats.id AND
        items_stats_#{i.id}.item_id=#{i.id}) "
      end
      stat_ids = Stat.all(
        :select => "items_stats_#{items.first.id}.stat_id",
        :conditions => { :question_id => question_id },
        :joins => joins
      ).map(&:stat_id)
      if stat_ids.length > 1
        # merge multiple stats for same item group
        stats = find(stat_ids)
        stat = stats.shift
        stats.each do |el|
          stat.votes += el.votes
          stat.views += el.views
        end
        stat.score = score((stat.rank_algorithm || default_rank_algo).data.to_i, stat.votes, stat.views)
        stat.save!
        stat
      else
        !stat_ids.empty? && find(stat_ids.first)
      end
    end

    # Compute score as |p|^alpha, with p = 2 * votes - views, sign(n) = n / n.abs.
    def score(alpha, votes, views) #:doc:
      n = 2 * votes - views
      n != 0 ? (n / n.abs) * (n.abs) ** alpha : 0
    end

    private
      def default(question_id, votes = 0)
        rank_algo = default_rank_algo
        { :views => 1,
          :votes => votes,
          :question_id => question_id,
          :score => score(rank_algo.data.to_i, votes, 1),
          :rank_algorithm_id => rank_algo.id
        }
      end

      def default_rank_algo
        RankAlgorithm.find(DEFAULT_RANK_ALGO)
      end
  end
end
