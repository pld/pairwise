require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ItemsStat do
  before(:each) do
    @valid_attributes = {
      :item_id => 1,
      :stat_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    ItemsStat.create!(@valid_attributes)
  end

  it 'should require item id' do
    ItemsStat.create(@valid_attributes.merge(:item_id => nil)).new_record?.should == true
  end

  it 'should require stat id' do
    ItemsStat.create(@valid_attributes.merge(:stat_id => nil)).new_record?.should == true
  end
end
