# encoding: utf-8
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/mavensmate.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/factory.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/metadata_helper.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/object.rb'

class DeployController < ApplicationController
  
  include MetadataHelper  
  
  layout "base", :only => [:index] 
          
  def index
    if File.not.exist? "#{ENV['TM_PROJECT_DIRECTORY']}/config/.org_metadata"
      MavensMate.build_index
    else     
      confirmed = TextMate::UI.request_confirmation(
        :title => "MavensMate",
        :prompt => "Would you like to refresh the local index of your Salesforce.com org's metadata?",
        :button1 => "Refresh",
        :button2 => "No")
    end  
    
    MavensMate.build_index if confirmed
    meta_array = eval(File.read("#{ENV['TM_PROJECT_DIRECTORY']}/config/.org_metadata")) #=> comprehensive list of server metadata    
    render "_deploy", :locals => { :meta_array => meta_array, :child_metadata_definition => CHILD_META_DICTIONARY }
  end
  
  def deploy_metadata  
    begin
      tree = eval(params[:tree])      
      params[:package] = tree
      result = MavensMate.deploy_to_server(params)
      render "_deploy_result", :locals => { :result => result }
    rescue Exception => e
      TextMate::UI.alert(:warning, "MavensMate", e.message + "\n" + e.backtrace.join("\n"))  
    end
  end
  
end