class PromptAlgorithmsController < ApplicationController
  before_filter :force_xml, :only => :list
  before_filter :admin_required, :except => :list

  # GET /prompt_algorithms
  # GET /prompt_algorithms.xml
  def index
    @prompt_algorithms = PromptAlgorithm.find(:all)
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @prompt_algorithms }
    end
  end
  
  # GET /prompt_algorithms/1
  # GET /prompt_algorithms/1.xml
  def show
    @prompt_algorithm = PromptAlgorithm.find(params[:id])
  
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @prompt_algorithm }
    end
  end
  
  # GET /prompt_algorithms/new
  # GET /prompt_algorithms/new.xml
  def new
    @prompt_algorithm = PromptAlgorithm.new
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @prompt_algorithm }
    end
  end
  
  # GET /prompt_algorithms/1/edit
  def edit
    @prompt_algorithm = PromptAlgorithm.find(params[:id])
  end
  
  # POST /prompt_algorithms
  # POST /prompt_algorithms.xml
  def create
    @prompt_algorithm = PromptAlgorithm.new(params[:prompt_algorithm])
  
    respond_to do |format|
      if @prompt_algorithm.save
        flash[:notice] = 'PromptAlgorithm was successfully created.'
        format.html { redirect_to(@prompt_algorithm) }
        format.xml  { render :xml => @prompt_algorithm, :status => :created, :location => @prompt_algorithm }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @prompt_algorithm.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /prompt_algorithms/1
  # PUT /prompt_algorithms/1.xml
  def update
    @prompt_algorithm = PromptAlgorithm.find(params[:id])
  
    respond_to do |format|
      if @prompt_algorithm.update_attributes(params[:prompt_algorithm])
        flash[:notice] = 'PromptAlgorithm was successfully updated.'
        format.html { redirect_to(@prompt_algorithm) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prompt_algorithm.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /prompt_algorithms/1
  # DELETE /prompt_algorithms/1.xml
  def destroy
    @prompt_algorithm = PromptAlgorithm.find(params[:id])
    @prompt_algorithm.destroy
  
    respond_to do |format|
      format.html { redirect_to(prompt_algorithms_url) }
      format.xml  { head :ok }
    end
  end

  # GET /prompt_algorithms/list
  def list
    @algorithms = PromptAlgorithm.all
  end
end