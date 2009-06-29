require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do
  describe 'force xml' do
    before do
      allow_message_expectations_on_nil
    end

    it 'should merge xml format into params' do
      @controller.params.should_receive(:include?).with(:format).and_return(false)
      @controller.params.should_receive(:merge!).with(:format => :xml)
      @controller.force_xml
    end

    it 'should not merge xml format into params with format' do
      @controller.params.should_receive(:include?).with(:format).and_return(true)
      @controller.params.should_not_receive(:merge!)
      @controller.force_xml
    end
  end

  describe 'admin required' do
    fixtures :users

    it 'should redirect if not logged in' do
      @controller.should_receive(:redirect_back_or_default).with('/').and_return(true)
      @controller.current_user = false
      @controller.admin_required
    end

    describe 'when logged in' do
      it 'should redirect if not admin' do
        login_as :quentin
        @controller.should_receive(:redirect_back_or_default).with('/').and_return(true)
        @controller.admin_required
      end

      it 'should not redirect if admin' do
        login_as :smurf
        @controller.should_not_receive(:redirect_back_or_default)
      end
    end
  end
end
