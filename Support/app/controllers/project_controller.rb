# encoding: utf-8
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/mavensmate.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/factory.rb' 
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/keychain.rb' 
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/lsof.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/object.rb'
require 'json'

class ProjectController < ApplicationController
  
  include MetadataHelper
  
  attr_accessor :client
  
  layout "base", :only => [:index_new, :index_edit]

  def index_new
    kill_server
    my_json = File.read("#{ENV['TM_BUNDLE_SUPPORT']}/resource/metadata_describe.json")
    render "_project_new", :locals => { :user_action => params[:user_action], :my_json => my_json, :child_metadata_definition => CHILD_META_DICTIONARY }
  end 
   
  def index_edit    
    if File.not.exist? "#{ENV['TM_PROJECT_DIRECTORY']}/config/.org_metadata"
      build_index
    else     
      confirmed = TextMate::UI.request_confirmation(
        :title => "MavensMate",
        :prompt => "Would you like to refresh the local index of your Salesforce.com org's metadata?",
        :button1 => "Refresh",
        :button2 => "No")
    end  
    
    build_index if confirmed
    
    project_array = eval(File.read("#{ENV['TM_PROJECT_DIRECTORY']}/config/.org_metadata")) #=> comprehensive list of server metadata
    
    require 'rubygems'
    require 'nokogiri'
    project_package = Nokogiri::XML(File.open("#{ENV['TM_PROJECT_DIRECTORY']}/src/package.xml"))
    project_package.remove_namespaces!
    project_package.xpath("//types/name").each do |node|
      object_definition = MavensMate::FileFactory.get_meta_type_by_name(node.text) || MavensMate::FileFactory.get_child_meta_type_by_name(node.text)  
      #puts object_definition.inspect + "<br/><br/>"
      is_parent = !object_definition[:parent_xml_name]
      server_object = project_array.detect { |f| f[:key] == node.text }
      
      next if server_object.nil? && is_parent
            
      if is_parent
        server_object[:selected] = true
        server_object[:select_mode] = (node.previous_element.text == "*") ? "all" : "some"
        select_all(server_object) if server_object[:select_mode] == "all"
        next if server_object[:selected] == "all"     
      end
      
      if not is_parent
        #=> CustomField
        parent_object_definition = MavensMate::FileFactory.get_meta_type_by_name(object_definition[:parent_xml_name]) #=> CustomObject
        prev_node = node.previous_element    
        while prev_node.not.nil? && prev_node.node_name == "members"
          next if prev_node.text.not.include? "."
          obj_name = prev_node.text.split(".")[0] #=> Lead
          obj_attribute = prev_node.text.split(".")[1] #=> Field_Name__c
           
          server_object = project_array.detect { |f| f[:key] == object_definition[:parent_xml_name] } #=> CustomObject
          sobject = server_object[:children].detect {|f| f[:title] == obj_name } #=> Lead
          sobject_metadata = sobject[:children].detect {|f| f[:title] == object_definition[:tag_name] } #=> fields
          sobject_metadata[:children].each do |item|
            if item[:title] == obj_attribute
              item[:selected] = "selected"
              break
            end
          end          
          prev_node = prev_node.previous_element || nil
        end
      end
      
      prev_node = node.previous_element    
      while prev_node.not.nil? && prev_node.node_name == "members"
        #skip items in folders for now
        if prev_node.include? "/"
          prev_node = prev_node.previous_element || nil
          next
        end
        child_object = server_object[:children].detect {|f| f[:key] == prev_node.text }
        child_object[:selected] = "selected" if child_object.not.nil?
        select_all(child_object) if object_definition[:child_xml_names]
        prev_node = prev_node.previous_element || nil
      end
      
      prev_node = node.previous_element    
      while prev_node.not.nil? && prev_node.node_name == "members"
        #process only items in folders
        if prev_node.text.not.include? "/"
          prev_node = prev_node.previous_element || nil
          next
        end
        child_object = server_object[:children].detect {|f| f[:key] == prev_node.text.split("/")[0]}        
        begin  
          child_object[:children].each do |gchild|
            gchild[:selected] = "selected" if gchild[:key] == prev_node.text
          end
        rescue Exception => e
          #puts e.message + "\n" + e.backtrace.join("\n")
        end
        prev_node = prev_node.previous_element || nil
      end
    end
    
    pconfig = MavensMate.get_project_config
    password = KeyChain::find_internet_password("#{pconfig['project_name']}-mm")
    
    render "_project_edit", :locals => { :package => project_package, :project_array => project_array, :child_metadata_definition => CHILD_META_DICTIONARY, :pname => pconfig['project_name'], :pun => pconfig['username'], :ppw => password, :pserver => pconfig['environment'] }
  end
  
  #updates current project
  def update
    begin
      tree = eval(params[:tree])  
      result = MavensMate.clean_project({ :update_sobjects => false, :update_package => true, :package => tree })
      render "_project_edit_result", :locals => { :message => result[:message], :success => result[:success] }
    rescue Exception => e
      TextMate::UI.alert(:warning, "MavensMate", e.message)
    end
  end
  
  #checks provided salesforce.com credentials    
  def login
    if params[:un].nil? || params[:pw].nil? || params[:server_url].nil?
      TextMate::UI.alert(:warning, "MavensMate", "Please provide Salesforce.com credentials before selecting metadata")
      abort
    end
      
    begin
      TextMate.call_with_progress( :title => "MavensMate", :message => "Validating Salesforce.com Credentials" ) do
        self.client = MavensMate::Client.new({ :username => params[:un], :password => params[:pw], :endpoint => params[:server_url] })
      end
      $stdout.flush
      flush
      if ! self.client.sid.nil? && ! self.client.metadata_server_url.nil?
        puts "<input type='hidden' value='#{self.client.sid}' id='sid'/>"
        puts "<input type='hidden' value='#{self.client.metadata_server_url}' id='murl'/>"
      end
    rescue Exception => e
      TextMate::UI.alert(:warning, "MavensMate", e.message)
      return
    end
  end
  
  #creates new local project from selected salesforce data
  def new_custom_project  
    begin
      tree = eval(params[:tree])
      params[:package] = tree
      result = MavensMate.new_project(params)
      return if result.nil?
      kill_server unless ! result[:is_success]
      render "_project_new_result", :locals => { :message => result[:error_message], :success => result[:is_success] }
    rescue Exception => e
      TextMate::UI.alert(:warning, "MavensMate", e.message)
    end
  end
  
  #checks out project from SVN, associates Salesforce.com server credentials  
  def checkout
    result = MavensMate.checkout_project(params)
    render "_project_new_result", :locals => { :message => result[:error_message], :success => result[:is_success] }
  end
  
  #starts TCP server to handle communication between html page and metadata api results
  def start_server
    #TODO: rewrite using thin
    
    exit if fork            # Parent exits, child continues.
    Process.setsid          # Become session leader.
    exit if fork            # Zap session leader.
    
    require 'socket'
    require 'uri'
    pid = fork do
      webserver = TCPServer.new('127.0.0.1', 7125)
      while (session = webserver.accept)
         session.print "HTTP/1.1 200/OK\r\nContent-type:application/json\r\n\r\n"
         request = session.gets
         tr = request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '')
         params = tr[tr.index("?")+1,tr.length-1]
         ps = params.split("&")
         sid = ""
         murl = ""
         meta_type = ""
         ps.each { |param|
           pair = param.split("=")
           if pair[0] == "sid"
             sid = pair[1]
           elsif pair[0] == "murl"
             murl = pair[1]
           elsif pair[0] == "key"
             meta_type = pair[1]
           end
         }
         cleanmurl = URI.unescape(murl)
         begin
           client = MavensMate::Client.new({ :sid => sid, :metadata_server_url => cleanmurl })
           meta_list = client.list(meta_type, false)
           session.puts meta_list
         rescue Exception => e
           #session.print e.message + "\n" + e.backtrace.join("\n")
           #session.close
         end
         session.close
      end
    end   
    Process.detach(pid)
    puts "<input type='hidden' value='#{pid}' id='pid'/>"
  end
      
  private
    
    #builds server index and stores in .org_metadata
    def build_index
      #mhash = eval(File.read("#{ENV['TM_BUNDLE_SUPPORT']}/resource/metadata_trim.txt"))
      mhash = eval(File.read("#{ENV['TM_BUNDLE_SUPPORT']}/resource/metadata.txt"))
      mhash.sort! { |a,b| a[:xml_name].downcase <=> b[:xml_name].downcase } 
      project_array = []
      progress = 0
      threads = []      
      TextMate.call_with_progress(:title =>'MavensMate',
               :summary => 'Building server metadata index',
               :details => 'This could take a while, but it\'ll all be worth it!',
               :indeterminate => true ) do |dialog|        
        client = MavensMate::Client.new
        mhash.each do |metadata|         
          threads << Thread.new {
            thread_client = MavensMate::Client.new({ :sid => client.sid, :metadata_server_url => client.metadata_server_url })
            #progress = progress + 100/mhash.length
            #dialog.parameters = {'summary' => 'Retrieving '+metadata[:xml_name],'progressValue' => progress }
            begin   
              project_array.push({
                :title => metadata[:xml_name],
                :key => metadata[:xml_name],
                :isLazy => false,
                :isFolder => true,
                :selected => false,
                :children => thread_client.list(metadata[:xml_name], false, "array"),
                :inFolder => metadata[:in_folder],
                :hasChildTypes => metadata[:child_xml_names] ? true : false
              })
            rescue  Exception => e
              puts e.message + "\n" + e.backtrace.join("\n")  
            end
          }        
        end
        threads.each { |aThread|  aThread.join }
      end                                            
      project_array.sort! { |a,b| a[:title].downcase <=> b[:title].downcase }
      File.open("#{ENV['TM_PROJECT_DIRECTORY']}/config/.org_metadata", 'w') {|f| f.write(project_array.inspect) }
    end
    
    #stops TCP server proc
    def kill_server
      if Lsof.running?(7125)
        Lsof.kill(7125)
      end
    end
    
    #selects all metadata in tree
    def select_all(obj)
      begin
        obj[:children].each do |child|
          child[:selected] = "selected"
          next if ! child[:children]
          child[:children].each do |grand_child|
            grand_child[:selected] = "selected"
            next if ! grand_child[:children]
            grand_child[:children].each do |great_grand_child|
              great_grand_child[:selected] = "selected"
            end
          end
        end
      rescue

      end
    end

end