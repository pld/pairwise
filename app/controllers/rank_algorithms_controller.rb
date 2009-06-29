class RankAlgorithmsController < ApplicationController
  before_filter :force_xml, :only => :list
  before_filter :admin_required, :except => :list

  # GET /rank_algorithms
  # GET /rank_algorithms.xml
  def index
    @rank_algorithms = RankAlgorithm.find(:all)
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rank_algorithms }
    end
  end

  # GET /rank_algorithms/1
  # GET /rank_algorithms/1.xml
  def show
    @rank_algorithm = RankAlgorithm.find(params[:id])
  
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @rank_algorithm }
    end
  end
  
  # GET /rank_algorithms/new
  # GET /rank_algorithms/new.xml
  def new
    @rank_algorithm = RankAlgorithm.new
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @rank_algorithm }
    end
  end
  
  # GET /rank_algorithms/1/edit
  def edit
    @rank_algorithm = RankAlgorithm.find(params[:id])
  end
  
  # POST /rank_algorithms
  # POST /rank_algorithms.xml
  def create
    @rank_algorithm = RankAlgorithm.new(params[:rank_algorithm])
  
    respond_to do |format|
      if @rank_algorithm.save
        flash[:notice] = 'RankAlgorithm was successfully created.'
        format.html { redirect_to(@rank_algorithm) }
        format.xml  { render :xml => @rank_algorithm, :status => :created, :location => @rank_algorithm }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @rank_algorithm.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /rank_algorithms/1
  # PUT /rank_algorithms/1.xml
  def update
    @rank_algorithm = RankAlgorithm.find(params[:id])
  
    respond_to do |format|
      if @rank_algorithm.update_attributes(params[:rank_algorithm])
        flash[:notice] = 'RankAlgorithm was successfully updated.'
        format.html { redirect_to(@rank_algorithm) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rank_algorithm.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /rank_algorithms/1
  # DELETE /rank_algorithms/1.xml
  def destroy
    @rank_algorithm = RankAlgorithm.find(params[:id])
    @rank_algorithm.destroy
  
    respond_to do |format|
      format.html { redirect_to(rank_algorithms_url) }
      format.xml  { head :ok }
    end
  end

  # GET /rank_algorithms/list
  def list
    @algorithms = RankAlgorithm.all
  end
end