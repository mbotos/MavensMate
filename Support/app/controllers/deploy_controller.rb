# encoding: utf-8
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/mavensmate.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/factory.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/metadata_helper.rb'

class DeployController < ApplicationController
  
  include MetadataHelper  
  
  layout "application"
          
  def index
    render "_deploy", :locals => { :my_json => project_json }
  end
  
  def deploy_metadata  
    tree = eval((params[:tree]))
    params[:selected_types] = tree
    
    #require 'logger'
    #log = Logger.new(STDOUT)
    #log.level = Logger::INFO

    #log.info "TREE: " + params[:selected_types].inspect + "<br/>"
    #log.info "PARAMS: " + params.inspect
    result = MavensMate.deploy_to_server(params)
    render "_deploy_result", :locals => { :result => result, :message => result[:error_message], :success => result[:is_success] }
  end
  
  private
  
    def project_json
      #[{"title":"analyticSnapshots","isLazy":true,"isFolder":true,"directory_name":"analyticSnapshots","meta_type":"AnalyticSnapshot","select":false}]
      json = '['
      Dir.foreach("#{ENV['TM_PROJECT_DIRECTORY']}/src") {|item| 
        next if item.include? "." or item.include? ".."
        mt = MavensMate::FileFactory.get_meta_type_by_dir(item)
        #puts mt.inspect
        children = ''
        Dir.foreach("#{ENV['TM_PROJECT_DIRECTORY']}/src/#{item}") {|child| 
          next if child == "." or child == ".." or child == ".svn" or child == ".git"
          next if child.include? "-meta.xml"
          child = child.split('.')[0]
          children << '{"title":"'+child+'","isLazy":false,"isFolder":false,"addClass":"custom1"},'
        }
        json << '{'
        json << '"title":"'+item+'",expand:true,"meta_type":"'+mt[:xml_name]+'","isLazy":false,"isFolder":true,"directory_name":"'+item+'","children":['+children+']'
        json << '},'
      }
      json << ']'
      json.gsub!(',]', ']')
      return json
    end
  
end