class ItemsStat < ActiveRecord::Base
  belongs_to :item
  belongs_to :stat

  validates_presence_of :item_id
  validates_presence_of :stat_id
end
