require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptAlgorithm do
  before(:each) do
    @valid_attributes = {
      :name => "1",
      :data => "1"
    }
  end

  it "should create a new instance given valid attributes" do
    PromptAlgorithm.create!(@valid_attributes)
  end
end
