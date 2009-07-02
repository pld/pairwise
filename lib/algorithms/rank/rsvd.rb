require 'linalg'
require File.dirname(__FILE__) + '/rsvd/rsvd_fast'

module Algorithms::Rank::RSVD
  include Linalg
  include RsvdFast
  FILE_PREFIX = File.dirname(__FILE__) + '/rsvd/bin/rsvd_save'
  Inf = 1.0/0

  def row_list(question_id, row = 1)
    h, v, p, items = svd(question_id)
    p.row(row).to_a.flatten.zip(items).sort_by { |el| -el[0] }
  end
  
  def svd(question_id, start_k = 0, end_k = 10, h = 0.001)
    old_sol = stored_solution(question_id)
    num_prompts = old_sol && old_sol.shift
    if num_prompts == true
      old_sol
    else
      num_prompts ||= ::Prompt.count(:conditions => { :question_id => question_id })
      votes, visits, items = make_vote_data(question_id)
      v_len = visits.length
      p_len = items.length
      if old_sol
        h, v_old, p_old = old_sol
      else
        tmp, h, v_old, p_old = load_solution(question_id) || [
          nil, h,
          DMatrix.new(v_len, start_k + 1) { rand },
          DMatrix.new(start_k + 1, p_len) { rand }
        ]
      end
      tmp = v_old
      v_old = DMatrix.new(v_len, start_k + 1)
      0.upto(start_k) { |i| v_old.replace_column(i, tmp.col(i)) }
      tmp = p_old
      p_old = DMatrix.new(start_k + 1, p_len)
      0.upto(start_k) { |i| p_old.replace_row(i, tmp.row(i)) }

      for i in start_k...end_k do
        scores = v_old * p_old
        puts "k: #{i} of #{end_k}, h: #{h}, dims: #{scores.dimensions.inspect}"
        res = matrix_approximation(scores.to_a.flatten, v_len, p_len, votes.values, h)
        v = res.first(v_len)
        p = res.last(p_len)
        v = DMatrix.new(v_len, 1) { |i,j| v[i] }
        p = DMatrix.new(1, p_len) { |i,j| p[j] }
        v_old = DMatrix.join_columns(v_old.columns.map { |x| x } + v.columns.map { |x| x })
        p_old = DMatrix.join_rows(p_old.rows.map { |x| x } + p.rows.map { |x| x })
        save_solution(question_id, num_prompts, h, v_old, p_old, items, visits)
      end
      [h, v_old, p_old, items, visits]
    end
  end

  private
  # we use the C extension version:
  # matrix_approximation(scores_old, v_len, p_len, votes, h);
  # scores_old: flat array of scores
  # votes: array of visits each visit an array of winning items followed
  # by losing item.
  # --
  # Approximate matrices v and p
  # ==== Return
  # ==== Parameters
  # scores_old<DMatrix>:: matrix of dot product of old v,p
  # votes<Hash>:: hash of visits to array of [winner, loser] arrays fo
  # pairs visitor voted on.
  # h<Float>:: step size
  def _ruby_matrix_approximation(scores_old, votes, h = 0.001) #:doc:
    v_len = scores_old.vsize
    p_len = scores_old.hsize

    v = DMatrix.new(v_len, 1, 0.5)
    p = DMatrix.new(1, p_len, 0.1)

    old_num_errs = [Inf] * 10
    old_err = [Inf] * 10
    stop = false

    until stop do
      scores = v * p
      dv = DMatrix.new(v.vsize, v.hsize, 0)
      dp = DMatrix.new(p.vsize, p.hsize, 0)

      err = 0
      num_errs = 0

      for i in 0...votes.length
        for winner, loser in votes[i]
          winner_val = scores_old[i, winner] + scores[i, winner]
          loser_val = scores_old[i, loser] + scores[i, loser]

          e = winner_val - loser_val
          num_errs -= 1 if e > 0
          e = 1 - e
          err += e * e
          num_errs += 1

          dv[i] += h*2*e*(p[0,winner] - p[0,loser])
          adj = h*2*e*v[i,0]
          dp[0,loser] -= adj
          dp[0,winner] += adj
        end
      end

      puts "[#{num_errs}, #{err}]"

      v += dv
      p += dp

      old_num_errs << num_errs
      old_err << err

      stop = err_window(old_num_errs) && err_window(old_err)

      old_num_errs.shift
      old_err.shift
    end
    [v, p]
  end

  def err_window(m)
    0.upto(m.length - 2).inject(0) { |sum, i| sum += (m[i] - m[i + 1]).abs } / m.length < 1
  end


  # Make vote data from question id.  Note that this vote data format will
  # work with the C version of matrix_approximation but NOT with the Ruby
  # version.
  # ==== Return
  # votes hash, visits array, and items array as an array.
  # ==== Parameters
  # question_id<int>:: ID of question to construct vote data for.
  def make_vote_data(question_id) #:doc:
    result = ActiveRecord::Base.connection.execute(
      "SELECT items_votes.item_id AS winner_id, items_prompts.item_id AS
        loser_id, votes.tracking FROM votes INNER JOIN prompts ON (prompts.id=votes.prompt_id
        AND prompts.question_id=#{question_id}) INNER JOIN items_votes ON
        (items_votes.vote_id=votes.id) INNER JOIN items_prompts ON
        items_prompts.prompt_id=prompts.id AND items_prompts.item_id!=
        items_votes.item_id"
    )
    votes = {}
    visits = []
    items = []
    # use votes.tracking to distinguish visitors
    while rec = result.fetch_hash
      winner_id, loser_id = rec['winner_id'], rec['loser_id']
      for id in [winner_id, loser_id]
        items << id unless items.include?(id)
      end
      winner = items.index(winner_id)
      loser = items.index(loser_id)

      tracking = rec['tracking']
      unless visits.include?(tracking)
        votes[visits.length] = []
        visits << tracking
      end
      visit = visits.index(tracking)
      #          votes[visit] << [winner, loser]
      votes[visit] << winner << loser
    end
    result.free
    [votes, visits, items]
  end

  def save_solution(question_id, num_prompts, h, v, p, items, visits)
    File.open(name_for_question(question_id), 'w+') {
      |f| f.write(Marshal.dump([num_prompts, h, v, p, items, visits]))
    }
  end

  def load_solution(question_id)
    name = name_for_question(question_id)
    Marshal.load(File.open(name, 'r') { |file| file.read }) if File.exists?(name)
  end

  def name_for_question(question_id)
    "#{FILE_PREFIX}_#{question_id}.bin"
  end

  # Use stored solution unless no stored solution or solution is more than 1
  # day old and number of new prompts greater than 105% of old number of
  # prompts.
  # ==== Return
  # If described conditions met returns stored solution, otherwise false or
  # nil.
  # ==== Parameters
  # question_id<int>:: question ID.
  def stored_solution(question_id) #:doc:
    name = name_for_question(question_id)
    if File.exists?(name) && Time.now - File.mtime(name) < 1.day
      num_prompts = ::Prompt.count(:conditions => { :question_id => question_id })
      sol = load_solution(question_id)
      sol[0] = num_prompts > sol[0] * 1.05 ? num_prompts : true
      sol
    end
  end
end