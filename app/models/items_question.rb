class ItemsQuestion < ActiveRecord::Base
  belongs_to :item
  belongs_to :question

  validates_presence_of :item_id
  validates_presence_of :question_id
end
