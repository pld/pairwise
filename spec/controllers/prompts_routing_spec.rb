require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PromptsController do
  describe "route recognition" do
    it "should generate params for #vote" do
      params_from(:get, "/prompts/view/1").should == {:controller => "prompts", :action => "view", :id => '1'}
    end  
  end
end
