#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class User < ActiveRecord::Base
  def self.authenticate(login, password)
    user = find(:first, :conditions => ['login = ?', login])
    if user.nil? then
      return user
    end
    if user['password'] != password.crypt(user['password']) then
      return nil
    end
    return user
  end
end
