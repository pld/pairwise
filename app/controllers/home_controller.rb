class HomeController < ApplicationController
  skip_before_filter :login_required, :only => [:learn, :api, :about]

  def index
  end

  def api
  end

  def about
  end
  
  def learn
  end

  # Delete all data associated with the logged in user.
  def delete
    if request.post?
      current_user.destroy_data
      flash[:notice] = 'All data destroyed.'
    end
    redirect_to root_path
  end

  # Delete all items associated with the logged in user.
  def delete_items
    if request.post?
      current_user.destroy_items
      flash[:notice] = 'All item data destroyed.'
    end
    redirect_to root_path
  end
end