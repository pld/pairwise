require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ItemsQuestion do
  before(:each) do
    @valid_attributes = {
      :item_id => "1",
      :question_id => "1",
      :position => "1",
      :wins => "1",
      :ratings => "1"
    }
  end

  it "should create a new instance given valid attributes" do
    ItemsQuestion.create!(@valid_attributes)
  end
end
