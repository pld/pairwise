require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RankAlgorithm do
  before(:each) do
    @valid_attributes = {
      :name => "1",
      :data => "1"
    }
  end

  it "should create a new instance given valid attributes" do
    RankAlgorithm.create!(@valid_attributes)
  end
end
