require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptRequest do
  before(:each) do
    @valid_attributes = {
      :question_id => "1",
      :voter_id => "1"
    }
  end

  it "should create a new instance given valid attributes" do
    PromptRequest.create!(@valid_attributes)
  end
end
