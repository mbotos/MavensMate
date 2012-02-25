MM_ROOT = File.dirname(__FILE__)
ENV['TM_BUNDLE_SUPPORT'] = MM_ROOT + "/.."

SUPPORT = ENV['TM_SUPPORT_PATH']
BUNDLESUPPORT = ENV['TM_BUNDLE_SUPPORT']
require SUPPORT + '/lib/exit_codes'
require SUPPORT + '/lib/escape'
require SUPPORT + '/lib/textmate'
require SUPPORT + '/lib/ui'
require SUPPORT + '/lib/web_preview'
require SUPPORT + '/lib/progress'
require 'rexml/document'
require 'fileutils'   
require BUNDLESUPPORT + '/lib/client'
require BUNDLESUPPORT + '/lib/factory'
require BUNDLESUPPORT + '/lib/exceptions'
require BUNDLESUPPORT + '/lib/metadata_helper'
require BUNDLESUPPORT + '/lib/util'

STDOUT.sync = true
TextMate.min_support 10895

module MavensMate
  
  #>>TODO
  #-move all temporary processing to .org.mavens.mavensmate.random format
  #-refresh selected files from server   
  #-modify package.xml when new metadata is created from MavensMate    
  #-create project from package 
  #-changeset -> deploy
  #-list sobjects in picklist when creating trigger
  #-quick panel (html/css/js) to replace native textmate dialog to run MavensMate commands

  include MetadataHelper
   
  #creates new local project from salesforce metadata 
  def self.new_project(params)    
    validate [:internet, :mm_project_folder]
      
    if (params[:pn].nil? || params[:un].nil? || params[:pw].nil?)
      alert "Project Name, Salesforce Username, and Salesforce Password are all required fields!"
      return
    end
       
    project_folder = get_project_folder
    project_name = params[:pn]
  	if File.directory?("#{project_folder}#{project_name}")
  	  alert "Hm, it looks like this project already exists in your project folder."
      return
  	end
  	
    begin   
      puts '<div id="mm_logger">'
      un            = params[:un]
      pw            = params[:pw]
      server_url    = params[:server_url]
      vc_un         = params[:vc_un] || ""
      vc_pw         = params[:vc_pw] || ""
      vc_url        = params[:vc_url] || ""
      is_vc         = vc_url != ""                                                                                                 
      vc_alias      = params[:vc_alias] || "origin"
      vc_url.chop! if vc_url[vc_url.length-1,1] == "/" 
      vc_type       = params[:vc_type] || "SVN"
      vc_branch     = params[:vc_branch] || "master"
      vc_url        = vc_url + "/" + project_name if vc_type == "SVN" 
      endpoint      = (server_url.include? "test") ? "https://test.salesforce.com/services/Soap/u/#{MM_API_VERSION}" : "https://www.salesforce.com/services/Soap/u/#{MM_API_VERSION}"    
      
      Thread.abort_on_exception = true
      threads = []  
      TextMate.call_with_progress( :title => 'MavensMate', :message => 'Retrieving Project Metadata' ) do          
        MavensMate::FileFactory.put_project_directory(project_name) #put project directory in the filesystem 
        client = MavensMate::Client.new({ :username => un, :password => pw, :endpoint => endpoint })
        threads << Thread.new {          
          thread_client = MavensMate::Client.new({ :sid => client.sid, :metadata_server_url => client.metadata_server_url })
          hash = params[:package]
          tmp_dir = Dir.tmpdir 
          MavensMate::FileFactory.put_package("#{tmp_dir}/mmpackage", binding, false)
          project_zip = thread_client.retrieve({ :package => "#{tmp_dir}/mmpackage/package.xml" })            
          MavensMate::FileFactory.put_project_metadata(project_name, project_zip) #put the metadata in the project directory    
          add_to_keychain(project_name, pw)
          MavensMate::FileFactory.put_project_config(un, project_name, server_url)
          FileUtils.rm_rf "#{tmp_dir}/mmpackage" 
        }
        threads << Thread.new {
          #put object metadata 
          thread_client = MavensMate::Client.new({ :sid => client.sid, :metadata_server_url => client.metadata_server_url })
          object_response = thread_client.list("CustomObject", true)
          object_list = []
          object_response[:list_metadata_response][:result].each do |obj|
            object_list.push(obj[:full_name])
          end 
          object_hash = { "CustomObject" => object_list }               
          options = { :meta_types => object_hash }
          object_zip = thread_client.retrieve(options) #get selected metadata
          Dir.mkdir(project_folder+project_name+"/config") unless File.exists?(project_folder+project_name+"/config") 
          MavensMate::FileFactory.put_object_metadata(project_name, object_zip)
        } 
        threads.each { |aThread|  aThread.join }
        open_project(project_name) if ! is_vc 
        TextMate.go_to :file => "#{project_folder}#{project_name}/src/package.xml" if ! is_vc           
      end
      
      if is_vc
        require SUPPORT + '/lib/tm/process'
      	if vc_type == "SVN"
        	TextMate.call_with_progress( :title => 'MavensMate', :message => 'Importing to SVN Repository' ) do
        		Dir.chdir("#{project_folder}#{project_name}")	
        		TextMate::Process.run("svn import #{vc_url} --username #{vc_un} --password #{vc_pw} -m \"initial import\"", :interactive_input => false) do |str|
          			#STDOUT << htmlize(str, :no_newline_after_br => true)
        		end
        	end 
        	TextMate.call_with_progress( :title => 'MavensMate', :message => 'Checking out from SVN Repository' ) do
        		Dir.chdir("#{project_folder}")	
        		TextMate::Process.run("svn checkout --force #{vc_url} '#{project_name}'", :interactive_input => false) do |str|
          			#STDOUT << htmlize(str, :no_newline_after_br => true)
        		end         
        	end
    	  elsif vc_type == "Git"
    	    Dir.chdir("#{project_folder}#{project_name}")
    	    #puts ">> git init"
    	    TextMate::Process.run("git init", :interactive_input => false) do |str|
        			#puts htmlize(str, :no_newline_after_br => true)
      		end
    	    #puts ">> git remote add #{vc_alias} #{vc_url}"
    	    TextMate::Process.run("git remote add #{vc_alias} #{vc_url}", :interactive_input => false) do |str|
        			#puts htmlize(str, :no_newline_after_br => true)
      		end
    	    #puts ">> git add ."
    	    TextMate::Process.run("git add .", :interactive_input => false) do |str|
        			#puts htmlize(str, :no_newline_after_br => true)
      		end
    	    #puts ">> git commit -m \"First import\""
      		TextMate::Process.run("git commit -m \"First import\"", :interactive_input => false) do |str|
        			#puts htmlize(str, :no_newline_after_br => true)
      		end                                        
      		vc_branch = "HEAD:#{vc_branch}" if vc_branch != "master" 
    	    #puts ">> git push #{vc_alias} #{vc_branch}"
    	    TextMate::Process.run("git push #{vc_alias} #{vc_branch}", :interactive_input => false) do |str|
        			#puts htmlize(str, :no_newline_after_br => true)
      		end
    	  end
    	  open_project(project_name)
        TextMate.go_to :file => "#{project_folder}#{project_name}/src/package.xml"
      end
      
    rescue Exception => e
      puts "</div>"
      FileUtils.rm_rf("#{project_folder}#{project_name}")
      #return { :is_success => false, :error_message => e.message + "\n" + e.backtrace.join("\n"), :project_name => project_name } 
      return { :is_success => false, :error_message => e.message, :project_name => project_name } 
    end
    puts "</div>"
    return { :is_success => true, :error_message => "", :project_name => project_name }
  end
  
  #checks out salesforce.com project from svn, applies MavensMate nature
  def self.checkout_project(params)        
    validate [:internet, :mm_project_folder]
    
    if params[:vc_type] == "SVN"    
      if (params[:pn].nil? || params[:un].nil? || params[:pw].nil? || params[:vc_url].nil? || params[:vc_un].nil? || params[:vc_pw].nil?)
        alert "All fields are required to check out a project from SVN"
        abort
      end
    elsif params[:vc_type] == "Git"
      if params[:vc_url].nil?
        alert "Please specify the Git repository URL"
        abort
      end 
    end
    
    project_folder = get_project_folder
    project_name = params[:pn]
  	if File.directory?("#{project_folder}#{project_name}")
  	  alert "Hm, it looks like this project already exists in your project folder"
      abort
  	end
    
    begin
      puts '<div id="mm_logger">'
      #puts params.inspect + "<br/>"
      un          = params[:un]
      pw          = params[:pw]
      server_url  = params[:server_url]
      vc_un       = params[:vc_un] || ""
      vc_pw       = params[:vc_pw] || ""
      vc_url      = params[:vc_url] || ""
      vc_type     = params[:vc_type] || "SVN"
      vc_branch   = params[:vc_branch] || "master"
      endpoint    = (server_url.include? "test") ? "https://test.salesforce.com/services/Soap/u/#{MM_API_VERSION}" : "https://www.salesforce.com/services/Soap/u/#{MM_API_VERSION}"
      
      require SUPPORT + '/lib/tm/process'    
      Thread.abort_on_exception = true
      threads = []
    	object_zip = nil
    	TextMate.call_with_progress( :title => 'MavensMate', :message => 'Checking out from Repository' ) do
    	  threads << Thread.new {      
          Dir.mkdir(project_folder) unless File.exists?(project_folder)
      		if vc_type == "Git"
      		  TextMate::Process.run("git clone '#{vc_url}' -b '#{vc_branch}' '#{project_folder}#{project_name}'", :interactive_input => false) do |str|
          	  STDOUT << htmlize(str, :no_newline_after_br => true)
        		end
      		elsif vc_type == "SVN"
        		Dir.mkdir("#{project_folder}#{project_name}") unless File.exists?("#{project_folder}#{project_name}")
        		Dir.chdir("#{project_folder}")
        		TextMate::Process.run("svn checkout '#{vc_url}' '#{project_name}' --username #{vc_un} --password #{vc_pw}", :interactive_input => false) do |str|
          	  STDOUT << htmlize(str, :no_newline_after_br => true)
        		end
      		end   
    		}
    		threads << Thread.new {
    		  client = MavensMate::Client.new({ :username => un, :password => pw, :endpoint => endpoint })
          object_response = client.list("CustomObject", true)
          object_list = []
          object_response[:list_metadata_response][:result].each do |obj|
            object_list.push(obj[:full_name])
          end 
          object_hash = { "CustomObject" => object_list }               
          options = { :meta_types => object_hash }
          object_zip = client.retrieve(options) #get selected metadata
    		}
    		threads.each { |aThread|  aThread.join }
                                                    
        MavensMate::FileFactory.put_project_config(un, project_name, server_url)
    		add_to_keychain(project_name, pw)      		        
        Dir.mkdir(project_folder+project_name+"/config") unless File.exists?(project_folder+project_name+"/config") 
        MavensMate::FileFactory.put_object_metadata(project_name, object_zip)              
    		open_project(project_name)
    	end
    
    rescue Exception => e
      puts "</div>"
      FileUtils.rm_rf("#{project_folder}#{project_name}")
      return { :is_success => false, :error_message => e.message, :project_name => project_name } 
    end
    puts "</div>"
    return { :is_success => true, :error_message => "", :project_name => project_name }
  end
    
  #creates new metadata (ApexClass, ApexTrigger, ApexPage, ApexComponent)
  def self.new_metadata(options={})
    #meta_type, api_name, object_api_name   
    validate [:internet, :mm_project]
    
    begin
      puts '<div id="mm_logger">'
      object_name = options[:object_api_name] || ""
      TextMate.call_with_progress( :title => 'MavensMate', :message => 'Compiling New Metadata' ) do
        zip_file = MavensMate::FileFactory.put_local_metadata(:api_name => options[:api_name], :meta_type => options[:meta_type], :object_name => object_name, :dir => "tmp", :apex_class_type => options[:apex_class_type])
        client = MavensMate::Client.new
        result = client.deploy({:zip_file => zip_file, :deploy_options => "<rollbackOnError>true</rollbackOnError>"}) 
        #puts "result of new metadata is: " + result.inspect
        puts "</div>"
        if ! result[:check_deploy_status_response][:result][:success]       
          return result
        else
          zip_file = MavensMate::FileFactory.put_local_metadata(:api_name => options[:api_name], :meta_type => options[:meta_type], :object_name => object_name, :apex_class_type => options[:apex_class_type])
          TextMate.rescan_project    
          TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/src/#{META_DIR_MAP[options[:meta_type]]}/#{options[:api_name]}#{META_EXT_MAP[options[:meta_type]]}" 
          return result
        end
      end
    rescue Exception => e
      puts "</div>"
      #TextMate::UI.alert(:warning, "MavensMate", e.message + "\n" + e.backtrace.join("\n"))
      return { :is_success => false, :error_message => e.message } 
    end
  end
     
  #compiles selected file(s) or active file
  def self.save(active_file=false) 
    validate [:internet, :mm_project]
    result = nil
    begin
      puts '<div id="mm_logger">'
      compiling_what = (!active_file) ? "Selected Metadata" : File.basename(ENV['TM_FILEPATH'])
      TextMate.call_with_progress( 
        :title => "MavensMate", 
        :message => "Compiling #{compiling_what}",
        :indeterminate => true ) do |dialog|                
          zip_file = MavensMate::FileFactory.put_tmp_metadata(get_metadata_hash(active_file))     
          client = MavensMate::Client.new
          result = client.deploy({:zip_file => zip_file, :deploy_options => "<rollbackOnError>true</rollbackOnError>"})            
        puts result.inspect
      end
      puts "</div>"    
    rescue Exception => e
      #alert e.message + "\n" + e.backtrace.join("\n")
      alert e.message
    end
    if ! result[:check_deploy_status_response][:result][:success]       
      TextMate.exit_show_html(dispatch :controller => "deploy", :action => "show_compile_result", :result => result)        
    end
  end
    
  #refreshes the selected file from the server // TODO:selected *files*
  def self.refresh_selected_file     
    validate [:internet, :mm_project, :file_selected]

    begin
      TextMate.call_with_progress( :title => 'MavensMate', :message => 'Refreshing '+File.basename(ENV['TM_FILEPATH']+' from the server') ) do
        client = MavensMate::Client.new
        result_zip = client.retrieve({ :path => ENV['TM_FILEPATH'] }) 
        MavensMate::FileFactory.replace_file(ENV['TM_FILEPATH'], result_zip)
        TextMate.rescan_project
      end
    rescue Exception => e
      alert e.message
    end
  end
    
  #deletes selected file(s) from the server (and locally)
  def self.delete_selected_files
    validate [:internet, :mm_project]
    #puts get_selected_files
    deleting_what = (get_selected_files.length > 1) ? "selected metadata" : File.basename(ENV['TM_FILEPATH'])    
    confirmed = TextMate::UI.request_confirmation(
      :title => "MavensMate",
      :prompt => "Are you sure you want to delete #{deleting_what}?",
      :button1 => "Delete",
      :button2 => "Cancel")
    
    abort if ! confirmed
        
    begin
      TextMate.call_with_progress( :title => "MavensMate", :message => "Deleting #{deleting_what}" ) do
        zip_file = MavensMate::FileFactory.put_delete_metadata(get_metadata_hash)     
        client = MavensMate::Client.new
        result = client.deploy({:zip_file => zip_file})
        if result[:check_deploy_status_response][:result][:success]       
          get_selected_files.each do |f|
            FileUtils.rm_r f   
          end
          TextMate.rescan_project
        end
      end
    rescue Exception => e
      alert e.message
    end
    
    if ! result[:check_deploy_status_response][:result][:success]       
      TextMate.exit_show_html(dispatch :controller => "deploy", :action => "show_compile_result", :result => result)        
    end
  end
  
  #compiles entire project
  def self.compile_project    
    validate [:internet, :mm_project]
    result = nil
    begin
      puts '<div id="mm_logger">'
      TextMate.call_with_progress( :title => 'MavensMate', :message => 'Compiling Project' ) do
        zip_file = MavensMate::FileFactory.copy_project_to_tmp 
        client = MavensMate::Client.new
        result = client.deploy({:zip_file => zip_file, :deploy_options => "<rollbackOnError>true</rollbackOnError>"}) 
      end
      puts "</div>"    
    rescue Exception => e
      alert e.message
    end
    if result[:check_deploy_status_response][:result][:success] == false       
      TextMate.exit_show_html(dispatch :controller => "deploy", :action => "show_compile_result", :result => result)        
    end
  end
        
  #wipes local project and rewrites with server copies based on current project's package.xml, preserves svn/git      
  def self.clean_project(options={}) 
    validate [:internet, :mm_project]
    confirmed = false
    if ! options[:update_package]      
      confirmed = TextMate::UI.request_confirmation(
        :title => "Salesforce Project Cleaner",
        :prompt => "Your Salesforce project will be emptied and refreshed according to package.xml. Any local metadata (not on the Salesforce.com server) will be lost forever.",
        :button1 => "Clean")  
    else
       File.delete("#{ENV['TM_PROJECT_DIRECTORY']}/src/package.xml")
       confirmed = true
    end
    
    return if !confirmed
         
    begin
      threads = []
      client = nil
      TextMate.call_with_progress( :title => "MavensMate", :message => "Cleaning Project" ) do
        pd = ENV['TM_PROJECT_DIRECTORY']
        Dir.foreach("#{pd}/src") do |entry| #iterate the metadata folders
          next if entry.include? "."
          Dir.foreach("#{pd}/src/#{entry}") do |subentry| #iterate the files inside those folders
            next if subentry == '.' || subentry == '..' || subentry == '.svn' || subentry == '.git'
            FileUtils.rm_r "#{pd}/src/#{entry}/#{subentry}" #delete what's inside
          end
        end
        require 'fileutils'   
        #FileUtils.rm_r "#{pd}/config/objects" if File.directory? "#{pd}/config/objects"
        MavensMate::FileFactory.clean_directory("#{pd}/config/objects", ".object")        
       end 
       TextMate.call_with_progress( :title => "MavensMate", :message => "Connecting to Salesforce" ) do
         client = MavensMate::Client.new
       end
       TextMate.call_with_progress( :title => "MavensMate", :message => "Retrieving Fresh Metadata" ) do        
        threads << Thread.new {
          thread_client = MavensMate::Client.new({ :sid => client.sid, :metadata_server_url => client.metadata_server_url })
          if options[:package]
            hash = options[:package] 
            MavensMate::FileFactory.put_package("#{ENV['TM_PROJECT_DIRECTORY']}/src", binding, false)
          end
          project_zip = thread_client.retrieve({ :package => "#{ENV['TM_PROJECT_DIRECTORY']}/src/package.xml" })
          MavensMate::FileFactory.finish_clean(get_project_name, project_zip) #put the metadata in the project directory  
        }
        if options[:update_sobjects]
          threads << Thread.new {
            #put object metadata
            thread_client = MavensMate::Client.new({ :sid => client.sid, :metadata_server_url => client.metadata_server_url })
            object_response = thread_client.list("CustomObject", true)
            object_list = []
            object_response[:list_metadata_response][:result].each do |obj|
              object_list.push(obj[:full_name])
            end 
            object_hash = { "CustomObject" => object_list }               
            options = { :meta_types => object_hash }
            object_zip = thread_client.retrieve(options) #get selected metadata 
            Dir.mkdir("#{ENV['TM_PROJECT_DIRECTORY']}/config") unless File.exists?("#{ENV['TM_PROJECT_DIRECTORY']}/config") 
            MavensMate::FileFactory.put_object_metadata(get_project_name, object_zip)   
          }
        end                                      
        
        threads.each { |aThread|  aThread.join }                  
        TextMate.rescan_project
        if options[:update_package]   
           return { :success => true }
        end 
      end
    rescue Exception => e
      alert e.message
      return { :success => false, :message => e.message }  
      #alert e.message + "\n" + e.backtrace.join("\n")
    end   
  end
  
  #creates a local changeset
  def self.new_changeset(options={})
    begin
      TextMate.call_with_progress( :title => "MavensMate", :message => "Creating changeset" ) do        
        Dir.mkdir("#{ENV['TM_PROJECT_DIRECTORY']}/changesets") unless File.exists?("#{ENV['TM_PROJECT_DIRECTORY']}/changesets")
        client = MavensMate::Client.new
        where = "#{ENV['TM_PROJECT_DIRECTORY']}/changesets/#{options[:name]}"
        hash = options[:package] 
        MavensMate::FileFactory.put_package(where, binding, false)
        project_zip = client.retrieve({ :package => "#{ENV['TM_PROJECT_DIRECTORY']}/changesets/#{options[:name]}/package.xml" })
        MavensMate::FileFactory.extract(project_zip, where)
        TextMate.rescan_project
        FileUtils.rm_rf "#{ENV['TM_PROJECT_DIRECTORY']}/changesets/#{options[:name]}/package.xml"
        return { :success => true, :message => "" }
      end
    rescue
      return { :success => false, :message => e.message }
    end
  end
    
  #deploys project metadata to a salesforce.com server
  def self.deploy_to_server(params)
    validate [:internet, :mm_project]

    begin
      if params[:mode] == "async"
        endpoint = MavensMate::Util.get_sfdc_endpoint(params[:server_url])
        tmp_dir = MavensMate::FileFactory.put_tmp_directory
        hash = params[:package]
        deploy = true
        MavensMate::FileFactory.put_package(tmp_dir, binding, false)
        client = MavensMate::Client.new
        zip_file = client.retrieve({ :package => "#{tmp_dir}/package.xml" })
                        
        client = MavensMate::Client.new({ :username => params[:un], :password => params[:pw], :endpoint => endpoint })
        result = client.deploy({
          :zip_file => zip_file,
          :deploy_options => "<checkOnly>#{params[:check_only]}</checkOnly><rollbackOnError>true</rollbackOnError>"
        })
        MavensMate::FileFactory.remove_directory(tmp_dir)
        return result
      else
        puts '<div id="mm_logger">'
        TextMate.call_with_progress( :title => "MavensMate", :message => "Deploying to the server") do
          endpoint = MavensMate::Util.get_sfdc_endpoint(params[:server_url])
          tmp_dir = MavensMate::FileFactory.put_tmp_directory
          hash = params[:package]
          deploy = true
          MavensMate::FileFactory.put_package(tmp_dir, binding, false)
          client = MavensMate::Client.new
          zip_file = client.retrieve({ :package => "#{tmp_dir}/package.xml" })
                          
          client = MavensMate::Client.new({ :username => params[:un], :password => params[:pw], :endpoint => endpoint })
          result = client.deploy({
            :zip_file => zip_file,
            :deploy_options => "<checkOnly>#{params[:check_only]}</checkOnly><rollbackOnError>true</rollbackOnError>"
          })
          MavensMate::FileFactory.remove_directory(tmp_dir)
          puts "</div>"
          return result
        end  
      end
    rescue Exception => e
      #alert e.message + "\n" + e.backtrace.join("\n")
      puts "</div>"
      MavensMate::FileFactory.remove_directory(tmp_dir)
      alert e.message
    end
  end
  
  #runs apex tests in selected class
  def self.run_tests(tests)
    validate [:internet, :mm_project, :run_test]
    
    run_test_body = ""
    tests.each do |t|
      run_test_body << "<runTests>#{t}</runTests>"
    end
    
    run_test_body << "<rollbackOnError>true</rollbackOnError>"
    
    begin
      TextMate.call_with_progress( :title => "MavensMate", :message => "Running Apex unit tests" ) do
        zip_file = MavensMate::FileFactory.put_empty_metadata    
        client = MavensMate::Client.new
        puts '<div id="mm_logger">'
        result = client.deploy({:zip_file => zip_file, :deploy_options => run_test_body })
        puts '</div>'
        return result      
      end
    rescue Exception => e
      #alert e.message + "\n" + e.backtrace.join("\n")
      alert e.message
    end
    
  end
     
  #displays autocomplete dialog based on current word. supports sobject fields & apex primitive methods
  def self.complete
    require ENV['TM_SUPPORT_PATH'] + '/lib/ui'
    require ENV['TM_SUPPORT_PATH'] + '/lib/current_word'
    #current_word = ENV['TM_CURRENT_WORD']
    current_word = Word.current_word(/\.([-a-zA-Z0-9_]+)/,:left)
    puts current_word
    abort if current_word.nil?
    suggestions = []
        
    if File.exist?("#{ENV['TM_BUNDLE_SUPPORT']}/lib/apex/#{current_word.downcase!}.yaml")
      apex_methods({:method_type => "static_methods", :object => current_word}).each do |m|
        suggestions.push({ "display" => m })
      end
      selection = TextMate::UI.complete(suggestions, {:case_insensitive => true})
      prints suggestions[selection] if not selection.nil?
    else
      current_object = ""
      lines=[]
      File.open(ENV['TM_FILEPATH']) do |file|
         file.each_line do |line| 
             lines.push(line)
         end
      end
      lines = lines[0, ENV['TM_LINE_NUMBER'].to_i - 1]
      lines.reverse!
      lines.each_with_index do |line, index| 
        next if not line.include?(" #{current_word} ")
        line = line.slice(0, line.index(" #{current_word} "))
        line.reverse!
        line = line.slice(0, line.index(/[\[\]\(\)\s]/))
        current_object = line.reverse
        break
      end
    
      abort if current_object.nil?
    
      if File.exist?("#{ENV['TM_PROJECT_DIRECTORY']}/config/objects/#{current_object}.object")
        require 'rubygems'
        require 'nokogiri'
        doc = Nokogiri::XML(File.open("#{ENV['TM_PROJECT_DIRECTORY']}/config/objects/#{current_object}.object"))
        doc.remove_namespaces!
        doc.xpath("//fields/fullName").each do |node|
          suggestions.push({ "display" => node.text })
        end
        selection = TextMate::UI.complete(suggestions, {:case_insensitive => true})
        prints suggestions[selection] if not selection.nil?    
      else
        current_object.downcase!
        if File.exist?("#{ENV['TM_BUNDLE_SUPPORT']}/lib/apex/#{current_object}.yaml")
          apex_methods({:method_type => "instance_methods", :object => current_object}).each do |m|
            suggestions.push({ "display" => m })
          end
          selection = TextMate::UI.complete(suggestions, {:case_insensitive => true})
          prints suggestions[selection] if not selection.nil?
        end
      end
    end
  end
   
  #returns the project name
  def self.get_project_name
    yml = YAML::load(File.open(ENV['TM_PROJECT_DIRECTORY'] + "/config/settings.yaml"))
    project_name = yml['project_name']
  end
  
  #returns yaml project settings
  def self.get_project_config
    return YAML::load(File.open(ENV['TM_PROJECT_DIRECTORY'] + "/config/settings.yaml"))
  end
  
  #builds server index and stores in .org_metadata
  def self.build_index
    mhash = eval(File.read("#{ENV['TM_BUNDLE_SUPPORT']}/conf/metadata_dictionary"))
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
  
  #selects all metadata in tree
  def self.select_all(obj)
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
  
  #runs applescript that closes all textmate html windows
  def self.close_all_html_windows
    pid = fork do
      Thread.new do
        script_path = "#{ENV['TM_BUNDLE_SUPPORT']}/osx/closewindows.scpt"
        %x{osascript &>/dev/null '#{script_path}'}
      end
    end
    Process.detach(pid)
  end
  
  def self.close_deploy_window
    pid = fork do
      Thread.new do
        script_path = "#{ENV['TM_BUNDLE_SUPPORT']}/osx/closedeploywindow.scpt"
        %x{osascript &>/dev/null '#{script_path}'}
      end
    end
    Process.detach(pid)
  end
  
  #adds salesforce.com creds to the keychain
  def self.add_to_keychain(project_name, pw)
    %x{security add-generic-password -a '#{project_name}-mm' -s \"MavensMate: #{project_name}\" -w #{pw} -U}
  end
  
  private
    
    #returns a list of apex methods based on the object and method type supplied    
    def self.apex_methods(options={})
      require 'yaml'
      methods = []
      yml = YAML::load(File.open("#{ENV['TM_BUNDLE_SUPPORT']}/lib/apex/#{options[:object]}.yaml"))
      yml[options[:method_type]].each do |method|
        methods.push(method)
      end
      return methods
    end
    
    #validates textmate command
    def self.validate(options=[])
      if options.include?(:internet)
        if ! has_internet
          alert "You don't seem to have an active internet connection!"
          abort
        end
      end
      if options.include?(:mm_project)
        if ! is_mm_project
          alert "This doesn't seem to be a valid MavensMate project"
          abort
        end
      end
      if options.include?(:run_test)
        if ! File.extname(".cls")
          alert "This doesn't seem to be a valid Apex Class file" 
          abort
        end
      end
      if options.include?(:file_selected)
        if ENV['TM_FILEPATH'].nil?
          alert "Please select a file to refresh from the server"
          abort
        end
      end
      if options.include?(:mm_project_folder)
        if ENV['FM_PROJECT_FOLDER'].nil?
          alert "Please specify your projects folder by setting the 'FM_PROJECT_FOLDER' shell variable in TextMate preferences"
          abort
        end
      end
    end
    
    #creates a UI alert with the specified message
    def self.alert(message)
      TextMate::UI.alert(:warning, "MavensMate", message)
    end
    
    #returns the name of a file without its extension
    def self.get_name_no_extension(name)
      return name.split(".")[0]
    end
            
    #returns metadata hash of selected files  #=> {"ApexClass" => ["aclass", "anotherclass"], "ApexTrigger" => ["atrigger", "anothertrigger"]}
    def self.get_metadata_hash(active_file=false)
      selected_files = get_selected_files(active_file)     
      meta_hash = {}
      selected_files.each do |f|
        puts "selected file: " + f + "\n\n"
        next if ! f.include? "." #need files only, not directories
        next if f.include? "-meta.xml" #dont need meta files
        ext = File.extname(f) #=> .cls
        ext_no_period = File.extname(f).gsub(".","") #=> cls
        metadata_definition = MavensMate::FileFactory.get_meta_type_by_suffix(ext_no_period)      
        meta_type = metadata_definition[:xml_name]
        puts "meta_type: " + meta_type.inspect + "<br/>"

        if ! meta_hash.key? meta_type #key isn't there yet, put it in        
          if metadata_definition[:in_folder]
            arr = f.split("/")
            if arr[arr.length-2] != metadata_definition[:directory_name]
              meta_hash[meta_type] = [arr[arr.length-2]+"/"+File.basename(f, ext)] #file name with no extension
            else
              meta_hash[meta_type] = [File.basename(f, ext)] #file name with no extension
            end
          else
            meta_hash[meta_type] = [File.basename(f, ext)] #file name with no extension
          end
        else #key is there, let's add metadata to it
          meta_array = meta_hash[meta_type] #get the existing array
          if metadata_definition[:in_folder]
            arr = f.split("/")
            if arr[arr.length-2] != metadata_definition[:directory_name]
              meta_array.push(arr[arr.length-2]+"/"+File.basename(f, ext)) #file name with no extension
            else
              meta_array.push(File.basename(f, ext)) #add the new piece of metadata
            end
          else
            meta_array.push(File.basename(f, ext)) #file name with no extension
          end
          #meta_array.push(File.basename(f, ext)) #add the new piece of metadata
          meta_hash[meta_type] = meta_array #replace the key
        end 
      end
            
      puts "hash is: "+meta_hash.inspect      
      return meta_hash
    end
        
    #returns array of selected files #=> ["/users/username/projects/foo/classes/myclass123.cls", /users/username/projects/foo/classes/myclass345.cls"]
    def self.get_selected_files(active_file=false)
      if active_file
        return Array[ENV['TM_FILEPATH']]
      else
        begin
          selected_files = Shellwords.shellwords(ENV["TM_SELECTED_FILES"])
          selected_files.each do |f|
            next if f.include? "-meta.xml"        
            ext = File.extname(f).gsub(".","") #=> cls
            mt_hash = MavensMate::FileFactory.get_meta_type_by_suffix(ext)      
            if mt_hash[:meta_file]
              if ! selected_files.include? f + "-meta.xml" #if they didn't select the meta file, select it anyway
                selected_files.push(f + "-meta.xml")   
              end
            end
          end
          selected_files.uniq!
          return selected_files
        rescue
          return Array[ENV['TM_FILEPATH']]
        end
      end
    end
            
    #opens project in textmate
    def self.open_project(project_name)
      project_folder = get_project_folder
      Dir.chdir("#{project_folder}")
      %x{find . -type d -name '#{project_name}' -exec mate {} \\;}
    end
    
    #returns the selected location of projects
    def self.get_project_folder
      project_folder = ENV['FM_PROJECT_FOLDER']
    	project_folder +='/' unless project_folder.end_with?("/")
    end
    
    #pings google.com to determine whether there's an active internet connection
    def self.has_internet
      require 'socket' 
      begin 
        if ENV["http_proxy"]
          TCPSocket.new URI.parse(ENV["http_proxy"]).host, URI.parse(ENV["http_proxy"]).port 
        else
          TCPSocket.new 'google.com', 80 
        end   
      rescue SocketError 
        return false 
      end
      return true
    end
    
    #determines whether this is a mavensmate project
    def self.is_mm_project
      project_dir = ENV['TM_PROJECT_DIRECTORY'] + "/config"
      config_file = ENV['TM_PROJECT_DIRECTORY'] + "/config/settings.yaml"
      if ! File.directory?(project_dir) && ! File.exists?(config_file)
    	  return false
      end
      return true
    end

end