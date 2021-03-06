require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Vote do
  before(:each) do
    @valid_attributes = {
      :prompt_id => 1,
      :voter_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Vote.create!(@valid_attributes)
  end
end