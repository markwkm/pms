class Notifier < ActionMailer::Base
  def patch_submission(user, patch)
    @recipients = user['email']
    @from = 'plm@osdl.org'
    @subject = "Thank you for submitting patch '#{patch['name']}' to PLM!"

    @body['first_name'] = user['first']
    @body['last_name'] = user['last']
    @body['patch_name'] = patch['name']
    #
    # The request object and url_encode method apparently aren't available
    # from within a model.  Any ideas other than hardcoding?  We also want
    # to use the url_encoded patch name instead of the PLM id.
    #
    #@body['url'] = "http://#{request.host}/patches/show/#{url_encode(patch['name'])}\n"
    @body['url'] = "http://plm.osdl.org/patches/show/#{patch['id']}"
  end

  def filter_results(user, patch)
    @recipients = user['email']
    @from = 'plm@osdl.org'
    @subject = "'#{patch['name']}' Filter Results Summary"

    #
    # The request object and url_encode method apparently aren't available
    # from within a model.  Any ideas other than hardcoding?  We also want
    # to use the url_encoded patch name instead of the PLM id.
    #
    @body = "For patch details, download and filter run logs:\n"
    @body <<
        "http://plm.osdl.org/patches/show/#{patch['id']}\n"
    #    "http://#{request.host}/patches/show/#{url_encode(patch['name'])}\n"

    @body << "\nThe filter results are:\n"
    for filter_request in patch.filter_requests
      @body << sprintf("  %-18s %s %s\n",
          filter_request.filter['name'], filter_request['result'],
          filter_request['result_detail'])
    end

    @body << "\nThis patch applies to:\n"
    p = patch
    loop do
      p = Patch.find(p['patch_id'], :select => 'name, patch_id')
      @body << "  #{p['name']}\n"
      break if p['patch_id'].nil?
    end
  end
end
