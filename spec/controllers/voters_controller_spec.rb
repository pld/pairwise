require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VotersController do
  fixtures :users, :voters

  before(:each) do
    login_as('quentin')
  end

  describe "responding to GET list" do
    it "should return all of the users voters" do
      get :list
      assigns[:voters].should == Voter.find_all_by_user_id(1)
      assigns[:voters].each do |voter|
        voter.user_id.should == 1
      end
    end
  end
  
  describe "responding to POST add" do
    it "should create new voters" do
      xml_post :add, 'voters'
      voters = Voter.find_all_by_user_id(1)[-2,2]
      assigns[:voters].should == voters
      assigns[:voters].each do |voter|
        voter.features.first.name.should == "gender"
      end
      assigns[:voters].first.features.first.value.should == 0
      assigns[:voters].last.features.first.value.should == 1
    end
  end
  
  describe "responding to GET set" do
    it "should require a voter id of the user" do
      get :set, :id => 2
      response.status.should =~ /400/
    end
    
    it "should update the feature" do
      voter = Voter.find(1)
      voter.features.clear
      get :set, :id => 1, :gender => 1
      voter.reload
      feature = voter.features.find_by_name('gender')
      assigns[:voter].should == voter
      feature.value.should == 1
      voter.features.should == [feature]
    end
  end
end
