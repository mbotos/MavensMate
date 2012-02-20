# encoding: utf-8
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/mavensmate.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/factory.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/metadata_helper.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/object.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/util.rb'
class DeployController < ApplicationController
  
  include MetadataHelper  
  
  layout "base", :only => [:index, :show_compile_result] 
          
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
    
    connections = []
    begin
      pconfig = MavensMate.get_project_config
      pconfig['org_connections'].each do |connection| 
        pw = KeyChain::find_internet_password("#{pconfig['project_name']}-mm-#{connection['username']}")
        server_url = connection["environment"] == "production" ? "https://www.salesforce.com" : "https://test.salesforce.com" 
        connections.push({
          :un => connection["username"], 
          :pw => pw,
          :server_url => server_url
        })
      end 
    rescue Exception => e
      #no connections
    end 
    
    MavensMate.build_index if confirmed
    meta_array = eval(File.read("#{ENV['TM_PROJECT_DIRECTORY']}/config/.org_metadata")) #=> comprehensive list of server metadata    
    render "_deploy", :locals => { :meta_array => meta_array, :child_metadata_definition => CHILD_META_DICTIONARY, :connections => connections }
  end
  
  #deploys metadata to selected server
  def deploy_metadata  
    begin
      tree = eval(params[:tree])      
      params[:package] = tree
      result = MavensMate.deploy_to_server(params)
      result = MavensMate::Util.parse_deploy_response(result)
      render "_deploy_result", :locals => { :result => result, :is_check_only => params[:check_only] }
    rescue Exception => e
      TextMate::UI.alert(:warning, "MavensMate", e.message + "\n" + e.backtrace.join("\n"))  
    end
  end
  
  #special method only used for displaying the result of a compile file/project command via exit_show_html
  def show_compile_result  
    begin
      result = MavensMate::Util.parse_deploy_response(params[:result])
      render "_compile_result", :locals => { :result => result, :is_check_only => false }
    rescue Exception => e
      TextMate::UI.alert(:warning, "MavensMate", e.message + "\n" + e.backtrace.join("\n"))  
    end
  end
  
end