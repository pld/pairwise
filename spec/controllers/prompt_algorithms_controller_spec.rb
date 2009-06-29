require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptAlgorithmsController do
  fixtures :users, :prompt_algorithms
  
  before(:each) do
    login_as('quentin')
  end
  
  describe "responding to GET list" do
    it "should list rank algos" do
      get :list
      assigns[:algorithms].should == PromptAlgorithm.find(:all)
    end
  end
end