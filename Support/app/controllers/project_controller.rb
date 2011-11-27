# encoding: utf-8
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/mavensmate.rb'

class ProjectController < ApplicationController
  
  layout "application"
            
  def index
    render "_project", :locals => { :user_action => params[:user_action] }
  end
  
  def checkout
    result = MavensMate.checkout_project(params)
    render "_project_result", :locals => { :message => result[:error_message], :success => result[:is_success] }
  end
    
  def new_project  
    result = MavensMate.new_project(params)
    render "_project_result", :locals => { :message => result[:error_message], :success => result[:is_success] }
  end
  
end