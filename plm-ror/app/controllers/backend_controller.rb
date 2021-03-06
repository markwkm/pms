#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

require 'base64'
require 'bz2'

class BackendController < ApplicationController
  wsdl_service_name 'Backend'

  web_service_api PatchApi
  web_service_scaffold :invoke

  def add_patch(login, password, name, software_name, applies_patch_name, diff)
    user = User.find(:first, :conditions => ['login = ?', login])
    #
    # We intentionally want invalid logins or passwords to be ambiguous for the
    # user.
    #
    return -2 if user.nil?
    return -2 if user['password'] != password.crypt(user['password'])
    patch = Patch.new
    #
    # Check for valid software type and set the default strip level.
    #
    patch.software = Software.find(:first,
        :conditions => ['name = ?', software_name])
    return -3 if patch.software.nil?
    patch[:strip_level] = patch.software['default_strip_level']
    #
    # Check for valid patch to apply to.
    #
    patch.patch = Patch.find(:first,
        :select => 'id',
        :conditions => ['name = ? AND software_id = ?', applies_patch_name,
        patch.software['id']])
    return -4 if patch.patch.nil?
    #
    # Check the name of the patch to make sure it doesn't collide with names
    # we want to reserve for things like the Linux kernel or the PostgreSQL
    # database.
    #
    patch[:name] = name
    patch.user = user
    return -5 unless patch.check_acl
    patch[:diff] = diff
    patch[:md5sum] = Digest::MD5.hexdigest(Base64.decode64(patch[:diff]))
    Patch.transaction do
      return -1 unless patch.save
      #
      # Queue new filter requests.
      #
      patch.queue_filters
    end
    Notifier::deliver_patch_submission(user, patch) if ENABLE_EMAIL
    return patch[:id]
  end

  def command_set_get_content(software, id, command_set_type)
    Command.find_by_sql(
        'SELECT command, command_type, expected_result ' +
        'FROM commands c, command_sets_softwares st, command_sets cs, ' +
        '     softwares s ' +
        'WHERE c.command_set_id = st.command_set_id ' +
        '  AND st.software_id = s.id ' +
        "  AND s.name = '#{software}' " +
        '  AND st.command_set_id = cs.id ' +
        "  AND cs.command_set_type = '#{command_set_type}' " +
        "  AND #{id} >= min_patch_id " +
        "  AND #{id} <= max_patch_id " +
        'ORDER BY c.command_order, c.id');
  end

  def get_applies_tree(id)
    applies_tree = [id]
    loop do
      p = Patch.find_by_sql(
          'SELECT patch_id ' +
          'FROM patches ' +
          "WHERE id = #{id}")[0]
      break if ( p['patch_id'].nil? or p['patch_id'] == 0 )
      id = p['patch_id']
      applies_tree << id
    end
    return applies_tree
  end

  def get_name(id)
    begin
      patch = Patch.find(id, :select => 'name')
    rescue
      return nil
    end
    return patch['name']
  end

  def get_filter(id)
    filter = Filter.find(id, :select => 'file')
    return filter['file']
  end

  def get_patch(id)
    result = Array.new
    p = Patch.find(id)
    PatchDetail.new({ :remote_identifier => p[:remote_identifier],
        :path => p[:path], :source_id => p[:source_id],
        :reverse => p[:reverse], :strip_level => p[:strip_level],
        :diff => p[:diff] })
  end

  def get_request(my_type)
    filter_type_list = my_type.gsub(/:/, "', '")
    fr = nil;
    begin
      FilterRequest.transaction do
        filter_type = FilterType.find(:all,
            :conditions => ["code IN ('#{filter_type_list}')"])
        for filter_typ in filter_type
          filters = filter_typ.filters
          for filter in filters
            fr = filter.filter_requests.find(:first,
                :conditions => ["state = '#{STATE_QUEUED}'" ],
                :order => 'priority, patch_id')
            break unless fr.nil?
          end
          break unless fr.nil?
        end
        return nil if fr.nil?
        fr['state'] = STATE_PENDING
        return nil unless fr.save
      end
    rescue
      return nil
    end
    return [fr['id'], fr.patch['id'], fr.filter['id'],
        fr.filter['filename'], fr.filter['runtime'],
        fr.patch.software['name']]
  end

  def patch_add(user, password, name, path, remote_identifier,
      source_id, applies_id, content, file_type)
    user = User.find(:first, :conditions => ['login = ?', user])
    #
    # We intentionally want invalid logins or passwords to be ambiguous for the
    # user.
    #
    return -1 if user.nil?
    return -1 if user['password'] != password.crypt(user['password'])
    patch = Patch.new
    patch.user = user
    #
    # Check for valid software type and set the default strip level.
    #
    patch.source = Source.find(source_id)
    patch.software = patch.source.software
    return -2 if patch.software.nil?
    patch[:strip_level] = patch.software['default_strip_level']
    if applies_id != 0 and !content.empty? then
      #
      # Check for valid patch to apply to if not a baseline.
      #
      patch.patch = Patch.find(:first,
          :select => 'id',
          :conditions => ['id = ? AND software_id = ?', applies_id,
          patch.software['id']])
      return -3 if patch.patch.nil?
      patch[:md5sum] = Digest::MD5.hexdigest(Base64.decode64(content))
      #
      # Recase the patch to a Base64 uuencoded patch instead of a compressed
      # file, if necessary.
      #
      case file_type
      when 'bzip2'
        patch[:diff] =
            Base64.encode64(BZ2::Reader.new(Base64.decode64(content)).read)
      when 'gzip'
        patch[:diff] =
            Base64.encode64(Zlib::GzipReader.new(Base64.decode64(content)).read)
      else
        patch[:diff] = content
      end
    else
      #
      # This is a baseline.
      #
      patch[:md5sum] = nil
      patch[:diff] = nil
    end
    #
    # Check the name of the patch to make sure it doesn't collide with names
    # we want to reserve for things like the Linux kernel or the PostgreSQL
    # database.
    #
    patch[:name] = name
    return -4 unless patch.check_acl
    # This is a patch, I am not sure where it is failing
    if path =~ /^#<SOAP::Mapping::Object/ then
        patch[:path] = nil
    else
        patch[:path] = path
    end
    patch[:remote_identifier] = remote_identifier
    #
    # For some bizarre reason, the patch.save is not attempting an insert.
    # Do the insert directly until we can figure out why.
    #
    Patch.transaction do
#      return -5 unless patch.save
      ActiveRecord::Base.connection.insert(
          'INSERT INTO patches (user_id, source_id, software_id, strip_level, ' +
          '                     patch_id, md5sum, diff, name, path, ' +
          '                     remote_identifier) ' +
          "VALUES (#{user['id']}, #{patch.source['id']}, " +
          "        #{patch.software['id']}, #{patch['strip_level']}, " +
          "        #{patch['patch_id'].nil? ? 'NULL' : patch['patch_id']}, " +
          "        #{patch['md5sum'].nil? ? 'NULL' : "'" + patch['md5sum'] + "'"}, " +
          "        #{patch['diff'].nil? ? 'NULL' : "'" + patch['diff'] + "'"}, " +
          "        '#{patch['name']}', '#{patch['path']}', " +
          "        '#{patch['remote_identifier']}')")
      patch = Patch.find(:first, :select => 'id, software_id', :conditions => ['name = ?', patch['name']])
      #
      # Queue new filter requests.
      #
      patch.queue_filters
    end
    return patch[:id]
  end

  def patch_find_by_name(name)
    p = Patch.find(:first, :select => 'id', :conditions => ['name = ?', name.strip])
    return 0 if p.nil?
    return p['id']
  end

  def patch_get_list(field, id)
    ret = Array.new
    case field
    when 'reverse'
      for i in id
        patch = Patch.find_by_sql(
            'SELECT reverse ' +
            'FROM patches ' +
            "WHERE id = #{i}")[0]
        ret << patch[:reverse]
      end
    end
    return ret
  end

  def patch_get_value(id, field)
    ret = 0
    #
    # Custom SQL to avoid reading the patch from the database using the
    # object relational model.
    #
    p = Patch.find_by_sql(
        "SELECT #{field} " +
        'FROM patches ' +
        "WHERE id = #{id}")[0]
    ret = p.nil? ? '0' : p["#{field}"]
    return ret
  end

  def software_verify(name)
    software = Software.find(:first, :conditions => ['name = ?', name])
    return software[:id] unless software.nil?
    0
  end

  def set_filter_request_state(request_id, state)
      fr = FilterRequest.find(request_id)
      fr['filter_request_state_id'] = state
      return 0 unless fr.save
      return 1
  end

  def source_get(id)
    Source.find(id)
  end

  def source_get_by_software(software_id)
    Source.find(:all, :conditions => ['software_id = ?', software_id])
  end

  def source_sync_by_source(source_id)
    SourceSync.find(:all, :conditions => ['source_id = ?', source_id])
  end

  def submit_result(request_id, filter_result, output)
    modified_result = nil
    if filter_result =~ /RESULT: (\w+)/ then
        modified_result = $1
#    else
#        warn "Missing required information from results (result)"
    end

    #
    # Set the plm_filter_request_state_id depending on the result.
    #
    if modified_result == 'PASS' then
        state = STATE_COMPLETED
    else
        state = STATE_FAILED
    end

    result_detail = nil
    if filter_result =~ /RESULT-DETAIL: (.+)$/ then
        result_detail = $1;
#    else
#        warn "Missing required information from results (result-detail)"
    end

    fr = nil
    FilterRequest.transaction do
      fr = FilterRequest.find(request_id)
      fr['result'] = modified_result
      fr['result_detail'] = result_detail
      fr['output'] = output
      fr['state'] = state
      fr.save
    end

    #
    # Send an email to the patch owner with a summary of all the filter
    # request results only after all the filters have run.
    #
    count_all = FilterRequest.count("patch_id = #{fr['patch_id']}")
    count_done = FilterRequest.count("patch_id = #{fr['patch_id']} AND (state = '#{STATE_COMPLETED}' OR state = '#{STATE_FAILED}')")
    if ENABLE_EMAIL and count_all == count_done
      Notifier::deliver_filter_results(fr.patch.user, fr.patch)
    end
  end

  def user_verify(user, password)
    user = User.find(:first, :conditions => ['login = ?', user])
    unless user.nil? then
      return user['id'] if user['password'] == password.crypt(user['password'])
    end
    0
  end

  def verify_patch(name, software=nil)
    begin
      #
      # I don't think we can really set default values for web service calls
      # so this should cover all of our bases.
      #
      if software.nil? or software.empty?
        patch = Patch.find(:first,
            :select => 'id',
            :conditions => ['name = ?', name.strip])
      else
        patch = Patch.find(:first,
            :select => 'id',
            :conditions => ['patches.name = ? AND softwares.name = ?',
                name.strip, software.strip])
      end
    rescue
      return false
    end
    return false if patch.nil?
    return true
  end
end
