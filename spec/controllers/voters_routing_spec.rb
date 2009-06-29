require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VotersController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "voters", :action => "index").should == {:path => "/voters", :method => :get}
    end
  
    it "should map #new" do
      route_for(:controller => "voters", :action => "new").should == {:path => "/voters/new", :method => :get}
    end
  
    it "should map #show" do
      route_for(:controller => "voters", :action => "show", :id => "1").should == {:path => "/voters/1", :method => :get}
    end
  
    it "should map #edit" do
      route_for(:controller => "voters", :action => "edit", :id => "1").should == {:path => "/voters/1/edit", :method => :get}
    end
  
    it "should map #update" do
      route_for(:controller => "voters", :action => "update", :id => "1").should == {:path => "/voters/1", :method => :put}
    end
  
    it "should map #destroy" do
      route_for(:controller => "voters", :action => "destroy", :id => "1").should == {:path => "/voters/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/voters").should == {:controller => "voters", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/voters/new").should == {:controller => "voters", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/voters").should == {:controller => "voters", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/voters/1").should == {:controller => "voters", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/voters/1/edit").should == {:controller => "voters", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/voters/1").should == {:controller => "voters", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/voters/1").should == {:controller => "voters", :action => "destroy", :id => "1"}
    end
  end
end
