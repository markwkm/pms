class LoginController < ApplicationController
  def index
  end

  def authenticate
    @session["user"] = User.authenticate(@params[:user]['login'],
        @params[:user]['password'])
    unless @session['user'].nil? then
      if @session['return_to']
        redirect_to_path(@session['return_to'])
        @session['return_to'] = nil
      else
        redirect_to :controller => 'patches', :action => 'user'
      end
    else
      flash[:notice] = 'login failed'
      render :action => 'index'
    end
  end

  def logout
      reset_session
      redirect_to '/'
  end
end
