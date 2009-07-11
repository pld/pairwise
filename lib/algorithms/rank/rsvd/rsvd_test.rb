require File.dirname(__FILE__) + '/rsvd_fast'
require 'rubygems'
require 'activerecord'
require 'linalg'
include Linalg
include RsvdFast

def make_vote_data(question_id)
   ActiveRecord::Base.establish_connection(
    :adapter  => "mysql",
    :host     => "localhost",
    :username => "princeton",
    :password => "princeton",
    :database => "pairwise"
  )
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
  # user votes.tracking to distinguish visitors
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
    votes[visit] << winner << loser
  end
  result.free
  [votes, visits, items]
end

votes, visits, items = make_vote_data(142)

v_len = visits.length
p_len = items.length

v_old, p_old = [
  DMatrix.new(v_len, 1) { rand },
  DMatrix.new(1, p_len) { rand }
]

for i in 0...10
  scores = v_old * p_old
  puts "k: #{i}, dims: #{scores.dimensions.inspect}"
  res = matrix_approximation(scores.to_a.flatten, v_len, p_len, votes.values, 0.001)
  break if res == false
  v = res.first(v_len)
  p = res.last(p_len)
  v = DMatrix.new(v_len, 1) { |i,j| v[i] }
  p = DMatrix.new(1, p_len) { |i,j| p[j] }
  v_old = DMatrix.join_columns(v_old.columns.map { |x| x } + v.columns.map { |x| x })
  p_old = DMatrix.join_rows(p_old.rows.map { |x| x } + p.rows.map { |x| x })
end

puts p_old.row(2).to_a.flatten.zip(items).sort.inspect if res

