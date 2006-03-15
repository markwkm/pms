require 'base64'
require 'bz2'
require 'md5'
require 'zlib'

class PatchesController < ApplicationController
  before_filter :authenticate,
      :except => [:download, :index, :list, :search, :search_result, :show,
      :view]

  def check_applies_id
    id = params['id']
    if id.empty? then
      render_text ''
      return
    end
    p = Patch.find(:first, :conditions => ['id = ?', id])
    if p.nil? then
      render_text "PLM ID <b>#{id}</b> not found."
    else
      render_text "<b>#{p['name']}</b>"
    end
  end

  def check_applies_name
    name = params['name']
    if name.empty? then
      render_text ''
      return
    end
    p = Patch.find(:first, :conditions => ['name = ?', name])
    if p.nil? then
      render_text "<b>#{name}</b> not found."
    else
      render_text "ok"
    end
  end

  def check_patch_name
    name = params['name']
    p = Patch.find(:first, :conditions => ['name = ?', name])
    if p.nil? then
      render_text ''
    else
      render_text "<b>#{name}</b> is already taken."
    end
  end

  def create
    #
    # Check to see if the patch we're applying to exists.
    #
    base_patch = Patch.find(:first, :select => 'id',
        :conditions => ['name = ?', params[:name]])
    unless base_patch
      flash[:notice] = 'Patch to apply to was not found.'
      render :action => 'new'
      return
    end
    #
    # Get the text into plain text before encoding it into base64.
    #
    case params[:patch][:diff].content_type.strip
      when 'application/x-tar'
        params[:patch][:diff] =
            Base64.encode64(Zlib::GzipReader.new(params[:patch][:diff]).read)
      when 'application/octet-stream'
        params[:patch][:diff] =
            Base64.encode64(BZ2::Reader.new(params[:patch][:diff]).read)
      else
        params[:patch][:diff] = Base64.encode64(params[:patch][:diff].read)
    end
    params[:patch][:md5sum] = Digest::MD5.hexdigest(params[:patch][:diff])
    @patch = Patch.new(params[:patch])
    @patch['user_id'] = @session['user']['id']
    @patch['patch_id'] = base_patch['id']
    Patch.transaction do
      if @patch.check_acl and @patch.save
        flash[:notice] = 'Patch was successfully created.'
        @patch.queue_filters
        redirect_to :action => 'show', :id => @patch
      else
        render :action => 'new'
      end
    end
  end

  def edit
    @patch = Patch.find(params[:id])
  end

  def download
    patch = Patch.find(params[:id])
    p = BZ2::Writer.new
    p.write(Base64.decode64(patch.diff))
    pbz2 = p.flush
    @response.headers['Content-type'] = 'application/octet-stream'
    @response.headers['Content-Disposition'] =
        "attachment; filename=#{patch.name}.patch.bz2"
    @response.headers['Accept-Ranges'] = 'bytes'
    @response.headers['Content-Length'] = pbz2.length
    @response.headers['Content-Transfer-Encoding'] = 'binary'
    render_text pbz2
  end

  def get_strip_level
    software_id = params['software_id']
    if software_id.empty? then
      render_text ''
    else
      @software = Software.find(software_id)
      render :partial => 'strip_level'
    end
  end

  def index
    list
    render :action => 'list'
  end

  def list
    @pagination_link_options = Hash.new
    @patch_pages, @patches = paginate :patches, :per_page => 10,
        :select => 'id, name, md5sum, software_id, user_id, patch_id',
        :order_by => 'id DESC'
  end

  def new
    @patch = Patch.new
  end

  def search
  end

  def search_result
    #
    # Make sure parameters get passed for the pagination links.
    #
    @pagination_link_options = Hash.new

    patch = @params[:patch]
    patch.each {
      |key, value|
      @pagination_link_options["patch[#{key}]"] = value
    }

    user = @params[:user]
    user.each {
      |key, value|
      @pagination_link_options["user[#{key}]"] = value
    } unless user.nil?

    unless @params['identifier'].nil? then
      @pagination_link_options['identifier'] = @params['identifier']
    end

    unless @params['search_created'].nil? then
      @pagination_link_options['search_created'] = @params['search_created']
    end

    table = Array.new
    condition = Array.new

    select1 =
        'SELECT COUNT(*) AS id '
    select2 =
        'SELECT p.id, p.name, p.md5sum, p.name, p.software_id, p.user_id, p.patch_id '

    if patch['software_id'].to_i > 0 then
      condition << "p.software_id = #{patch['software_id']}"
    end

    unless @params['search_created'].empty? then
      condition <<
          "p.created_on > now() - interval '#{@params['search_created']}'"
    end unless @params['search_created'].nil?

    unless @params['identifier'].empty? then
      name = @params['identifier'].gsub(/\*/, '%')
      if @params['identifier'].to_i == 0 then
        condition << "p.name SIMILAR TO '#{name}'"
      else
        condition <<
            "(p.id = #{@params['identifier']} " +
            " OR p.name SIMILAR TO '#{name}')"
      end
    end unless @params['identifier'].nil?

    unless user['login'].empty? then
      table << 'users u'
      condition << "u.login = '#{user['login']}'"
      condition << 'u.id = p.user_id'
    end unless user['login'].nil? unless user.nil?

    sql =
        'FROM patches p'

    table.each {
      |from|
      sql << ", #{from}"
    }
    sql << ' '

    count = 0
    condition.each {
      |where|
      sql << 'WHERE ' if count == 0
      sql << 'AND ' if count > 0
      sql << "#{where} "
      count += 1
    }

    limit = 10
    p = Patch.find_by_sql(select1 + sql)
    count = p[0]['id']
    @patch_pages = Paginator.new self, count, limit, @params['page']
    limit_offset =
        'ORDER BY p.id DESC ' +
        "LIMIT #{limit} " +
        "OFFSET #{@patch_pages.current.to_sql[1]}"
    @patches = Patch.find_by_sql(select2 + sql + limit_offset)

    render :action => 'list'
  end

  def show
    #
    # Specify :select so we don't grab the actual patch out of the database so
    # that the query will execute faster.
    #
    @patch = Patch.find(params[:id],
        :select => 'id, name, md5sum, name, software_id, user_id, patch_id')
    @filter_requests = FilterRequest.find_by_sql(
        'SELECT fr.* ' +
        'FROM filter_requests fr, filters f ' +
        'WHERE fr.filter_id = f.id ' +
        "  AND fr.patch_id = #{params[:id]} " +
        'ORDER BY f.name')
  end

  def update
    @patch = Patch.find(params[:id])
    if @patch.update_attributes(params[:patch])
      flash[:notice] = 'Patch was successfully updated.'
      redirect_to :action => 'show', :id => @patch
    else
      render :action => 'edit'
    end
  end

  def user
    @pagination_link_options = Hash.new

    @patch_pages, @patches = paginate :patches, :per_page => 10,
        :select => 'id, name, md5sum, software_id, user_id, patch_id',
        :conditions => ['user_id = ?', @session['user']['id']],
        :order_by => 'id DESC'
    render :action => 'list'
  end

  def view
    @patch = Patch.find(params[:id])
    @patch[:diff] = Base64.decode64(@patch[:diff])
    render :layout => false
  end
end
