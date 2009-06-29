# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090619190626) do

  create_table "features", :force => true do |t|
    t.integer  "voter_id",   :null => false
    t.string   "name",       :null => false
    t.integer  "value",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "features", ["name"], :name => "index_features_on_name"
  add_index "features", ["voter_id"], :name => "index_features_on_voter_id"

  create_table "items", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.boolean  "active",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "data"
    t.text     "tracking"
    t.integer  "voter_id"
  end

  add_index "items", ["active"], :name => "index_items_on_active"
  add_index "items", ["user_id"], :name => "index_items_on_user_id"

  create_table "items_prompt_requests", :id => false, :force => true do |t|
    t.integer "item_id",           :null => false
    t.integer "prompt_request_id", :null => false
  end

  add_index "items_prompt_requests", ["item_id"], :name => "index_items_prompt_requests_on_item_id"
  add_index "items_prompt_requests", ["prompt_request_id"], :name => "index_items_prompt_requests_on_prompt_request_id"

  create_table "items_prompts", :id => false, :force => true do |t|
    t.integer "item_id",   :null => false
    t.integer "prompt_id", :null => false
  end

  add_index "items_prompts", ["item_id"], :name => "index_items_prompts_on_item_id"
  add_index "items_prompts", ["prompt_id"], :name => "index_items_prompts_on_prompt_id"

  create_table "items_questions", :force => true do |t|
    t.integer  "item_id",                       :null => false
    t.integer  "question_id",                   :null => false
    t.integer  "wins",        :default => 0,    :null => false
    t.integer  "ratings",     :default => 0,    :null => false
    t.integer  "position",    :default => 1400, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "losses",      :default => 0
  end

  add_index "items_questions", ["item_id"], :name => "index_items_questions_on_item_id"
  add_index "items_questions", ["question_id"], :name => "index_items_questions_on_question_id"

  create_table "items_stats", :force => true do |t|
    t.integer "item_id",                :null => false
    t.integer "stat_id",                :null => false
    t.integer "losses",  :default => 0
    t.integer "wins",    :default => 0
  end

  add_index "items_stats", ["item_id"], :name => "index_items_stats_on_item_id"
  add_index "items_stats", ["stat_id"], :name => "index_items_stats_on_stat_id"

  create_table "items_votes", :id => false, :force => true do |t|
    t.integer "item_id", :null => false
    t.integer "vote_id", :null => false
  end

  add_index "items_votes", ["item_id"], :name => "index_items_votes_on_item_id"
  add_index "items_votes", ["vote_id"], :name => "index_items_votes_on_vote_id"

  create_table "prompt_algorithms", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "data",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prompt_requests", :force => true do |t|
    t.integer  "question_id",                :null => false
    t.integer  "voter_id",                   :null => false
    t.integer  "count",       :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prompt_requests", ["question_id"], :name => "index_prompt_requests_on_question_id"
  add_index "prompt_requests", ["voter_id"], :name => "index_prompt_requests_on_voter_id"

  create_table "prompts", :force => true do |t|
    t.integer  "question_id",                           :null => false
    t.integer  "prompt_algorithm_id",                   :null => false
    t.integer  "voter_id",                              :null => false
    t.boolean  "active",              :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prompts", ["question_id"], :name => "index_prompts_on_question_id"
  add_index "prompts", ["voter_id"], :name => "index_prompts_on_voter_id"

  create_table "questions", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "questions", ["user_id"], :name => "index_questions_on_user_id"

  create_table "rank_algorithms", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "data",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "stats", :force => true do |t|
    t.integer  "question_id",                        :null => false
    t.integer  "rank_algorithm_id"
    t.integer  "views",             :default => 0,   :null => false
    t.integer  "votes",             :default => 0,   :null => false
    t.float    "score",             :default => 0.0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stats", ["question_id"], :name => "index_stats_on_question_id"

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "state",                                    :default => "passive"
    t.datetime "deleted_at"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "voters", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "voters", ["user_id"], :name => "index_voters_on_user_id"

  create_table "votes", :force => true do |t|
    t.integer  "prompt_id",     :null => false
    t.integer  "voter_id",      :null => false
    t.integer  "response_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "tracking"
  end

  add_index "votes", ["prompt_id"], :name => "index_votes_on_prompt_id"
  add_index "votes", ["voter_id"], :name => "index_votes_on_voter_id"

end
