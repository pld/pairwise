ActionController::Routing::Routes.draw do |map|
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.activate '/activate/:id', :controller => 'users', :action => 'activate', :activation_code => nil
  map.learn '/learn', :controller => 'home', :action => 'learn'
  map.api '/api', :controller => 'home', :action => 'api'
  map.about '/about', :controller => 'home', :action => 'about'
  map.resources :users, :member => { :suspend   => :get,
                                     :unsuspend => :get,
                                     :purge     => :delete }
  map.resource :session
  map.resources(:items,
    :member => { :activate => [:post, :get], :suspend => [:post, :get], :delete => :post },
    :collection => {
      :add => :post,
      :list => :get
  })
  map.connect('items/list/:question_id/:rank_algorithm/:limit/:offset/:order/',
    :controller => 'items',
    :action => 'list',
    :defaults => { :question_id => 0, :rank_algorithm => 0, :limit => 0, :offset => 0, :order => 0 })
  map.resources :prompts, :collection => { :list => :get }, :member => { :view => :get }
  map.connect('prompts/list/:question_id/:item_id', :controller => 'prompts', :action => 'list',
    :defaults => { :question_id => 0, :item_id => 'A' })
  map.connect('prompts/create/:question_id/:voter_id/:n/:prime', :controller => 'prompts', :action => 'create',
    :conditions => { :method => [:post, :get] }, :defaults => { :n => 1, :prime => 0, :voter_id => 0 })
  map.resources :questions, :member => { :delete => :post }, :collection => { :list => :get, :add => :post }
  map.resources(:votes, :collection => { :list => :get, :add => [:post, :get] },
    :conditions => { :method => [:post, :get] })
  map.connect('votes/list/:question_id/:item_id', :controller => 'votes', :action => 'list',
    :defaults => { :question_id => 0, :item_id => 0 })
  map.connect('votes/add/:prompt_id/:voter_id/:response_time/:item_id/', :controller => 'votes', :action => 'add',
    :conditions => { :method => [:post, :get] }, :defaults => { :response_time => 0, :item_id => 0, :voter_id => 0 })
  map.resources :voters, :collection => { :list => :get, :add => :post }
  map.resources :rank_algorithms, :collection => { :build_stats => :get, :list => :get }
  map.resources :prompt_algorithms, :collection => { :list => :get }

  map.root :controller => 'home'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
