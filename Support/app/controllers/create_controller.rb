# encoding: utf-8
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/mavensmate.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/metadata_helper.rb'

class CreateController < ApplicationController
  
  include MetadataHelper  
  
  layout "application"
          
  def index
    render "_create", :locals => {:meta_type => params[:meta_type], :meta_label => META_LABEL_MAP[params[:meta_type]],  :message => ""}
  end
  
  def create_metadata  
    result = MavensMate.new_metadata(params[:meta_type], params[:api_name], params[:object_api_name])
    render "_create_result", :locals => { :message => result[:error_message], :success => result[:is_success] }
  end
  
end