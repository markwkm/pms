class FiltersController < ApplicationController
  before_filter :authenticate_admin, :except => [:show, :index, :list]

  def create
    @filter = Filter.new(params[:filter])
    @filter['file'] = Base64.encode64(@filter['file'].read)
    if @filter.save
      flash[:notice] = 'Filter was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @filter = Filter.find(params[:id])
  end

  def destroy
    Filter.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def index
    list
    render :action => 'list'
  end

  def list
    @filter_pages, @filters = paginate :filters, :per_page => 10,
        :select => 'id, name, filename, runtime',
        :order => 'UPPER(name)'
  end

  def new
    @filter = Filter.new
  end

  def show
    @filter = Filter.find(params[:id])
    @filter['file'] = Base64.decode64(@filter['file'])
  end

  def update
    @filter = Filter.find(params[:id])
    params['filter']['file'] = Base64.encode64(params['filter']['file'].read)
    if @filter.update_attributes(params[:filter])
      flash[:notice] = 'Filter was successfully updated.'
      redirect_to :action => 'show', :id => @filter
    else
      render :action => 'edit'
    end
  end
end
