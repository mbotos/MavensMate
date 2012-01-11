MM_ROOT = File.dirname(__FILE__)
ENV['TM_BUNDLE_SUPPORT'] = MM_ROOT + "/.."

SUPPORT = ENV['TM_SUPPORT_PATH']
BUNDLESUPPORT = ENV['TM_BUNDLE_SUPPORT']
require SUPPORT + '/lib/exit_codes'
require SUPPORT + '/lib/escape'
require SUPPORT + '/lib/textmate'
require SUPPORT + '/lib/ui'
require SUPPORT + '/lib/tm/process'
require SUPPORT + '/lib/web_preview'
require SUPPORT + '/lib/progress'
require 'rexml/document'
require 'fileutils'   
require BUNDLESUPPORT + '/lib/client'
require BUNDLESUPPORT + '/lib/factory'
require BUNDLESUPPORT + '/lib/exceptions'
require BUNDLESUPPORT + '/lib/metadata_helper'

STDOUT.sync = true
TextMate.min_support 10895

module MavensMate
  
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
      un = params[:un]
      pw = params[:pw]
      server_url = params[:server_url]
      svn_un = params[:svn_un] || ""
      svn_pw = params[:svn_pw] || ""
      svn_url = params[:svn_url] || ""
      endpoint = (server_url.include? "test") ? "https://test.salesforce.com/services/Soap/u/#{MM_API_VERSION}" : "https://www.salesforce.com/services/Soap/u/#{MM_API_VERSION}"
    
      is_svn = (svn_url.length > 0 && svn_un.length > 0 && svn_pw.length > 0) || false
        
      TextMate.call_with_progress( :title => 'MavensMate', :message => 'Retrieving Project Metadata' ) do          
        MavensMate::FileFactory.put_project_directory(project_name) #put project directory in the filesystem 
        client = MavensMate::Client.new({ :username => un, :password => pw, :endpoint => endpoint })
        if ! params[:selected_types].nil?
          options = { :meta_types => params[:selected_types]}
          project_zip = client.retrieve(options) #get selected metadata
        else
          project_zip = client.retrieve #get metadata in zip file
        end  
        MavensMate::FileFactory.put_project_metadata(project_name, project_zip) #put the metadata in the project directory    
        add_to_keychain(project_name, pw)
        MavensMate::FileFactory.put_project_config(un, project_name, server_url)
        
        #put object metadata
        object_response = client.list("CustomObject", true)
        object_list = []
        object_response[:list_metadata_response][:result].each do |obj|
          object_list.push(obj[:full_name])
        end 
        object_hash = { "CustomObject" => object_list }               
        options = { :meta_types => object_hash }
        object_zip = client.retrieve(options) #get selected metadata
        MavensMate::FileFactory.put_object_metadata(project_name, object_zip)
      
        open_project(project_name) if ! is_svn            
      end 

      if is_svn
      	TextMate.call_with_progress( :title => 'MavensMate', :message => 'Importing to SVN Repository' ) do
      		Dir.chdir("#{project_folder}#{project_name}")	
      		TextMate::Process.run("svn import #{svn_url} --username #{svn_un} --password #{svn_pw} -m \"initial import\"", :interactive_input => false) do |str|
        			STDOUT << htmlize(str, :no_newline_after_br => true)
      		end
      	end 
      	TextMate.call_with_progress( :title => 'MavensMate', :message => 'Checking out from SVN Repository' ) do
      		Dir.chdir("#{project_folder}")	
      		TextMate::Process.run("svn checkout --force #{svn_url} '#{project_name}'", :interactive_input => false) do |str|
        			STDOUT << htmlize(str, :no_newline_after_br => true)
      		end
      		open_project(project_name)
      	end
      end
      
    rescue Exception => e
      puts "</div>"
      FileUtils.rm_rf("#{project_folder}#{project_name}")
      #TextMate::UI.alert(:warning, "MavensMate", e.message + "\n" + e.backtrace.join("\n"))
      #return { :is_success => false, :error_message => e.message + "\n" + e.backtrace.join("\n"), :project_name => project_name } 
      return { :is_success => false, :error_message => e.message, :project_name => project_name } 
    end
    puts "</div>"
    return { :is_success => true, :error_message => "", :project_name => project_name } 
  end
  
  #checks out salesforce.com project from svn, applies MavensMate nature
  def self.checkout_project(params)        
    validate [:internet, :mm_project_folder]
        
    if (params[:pn].nil? || params[:un].nil? || params[:pw].nil? || params[:svn_url].nil? || params[:svn_un].nil? || params[:svn_pw].nil?)
      TextMate::UI.alert(:warning, "MavensMate", "All fields are required to check out a project from SVN")
      abort
    end
    
    project_folder = get_project_folder
    project_name = params[:pn]
  	if File.directory?("#{project_folder}#{project_name}")
  	  TextMate::UI.alert(:warning, "MavensMate", "Hm, it looks like this project already exists in your project folder.")
      abort
  	end
    
    begin
      puts '<div id="mm_logger">'
      puts params.inspect + "<br/>"
      un = params[:un]
      pw = params[:pw]
      server_url = params[:server_url]
      svn_un = params[:svn_un] || ""
      svn_pw = params[:svn_pw] || ""
      svn_url = params[:svn_url] || ""
      endpoint = (server_url.include? "test") ? "https://test.salesforce.com/services/Soap/u/#{MM_API_VERSION}" : "https://www.salesforce.com/services/Soap/u/#{MM_API_VERSION}"
   
    	TextMate.call_with_progress( :title => 'MavensMate', :message => 'Checking out from Repository' ) do
        Dir.mkdir(project_folder) unless File.exists?(project_folder)
    		#checkout project
    		Dir.mkdir("#{project_folder}#{project_name}") unless File.exists?("#{project_folder}#{project_name}")
    		Dir.chdir("#{project_folder}")	
    		TextMate::Process.run("svn checkout '#{svn_url}' '#{project_name}' --username #{svn_un} --password #{svn_pw}", :interactive_input => false) do |str|
      			#STDOUT << htmlize(str, :no_newline_after_br => true)
    		end
    		#add force.com nature if it's not there already
        MavensMate::FileFactory.put_project_config(un, project_name, server_url)
    		add_to_keychain(project_name, pw)
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
        if ! result[:is_success]        
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
    
    begin
      compiling_what = (!active_file) ? "Selected Metadata" : File.basename(ENV['TM_FILEPATH'])
      result = nil
      TextMate.call_with_progress( :title => "MavensMate", :message => "Compiling #{compiling_what}" ) do
        zip_file = MavensMate::FileFactory.put_tmp_metadata(get_metadata_hash(active_file))     
        client = MavensMate::Client.new
        result = client.deploy({:zip_file => zip_file, :deploy_options => "<rollbackOnError>true</rollbackOnError>"})
        #puts result.inspect
      end
      
      if ! result[:is_success]        
        begin
          if result[:messages]
            TextMate.go_to :file => ENV['TM_FILEPATH'], :line => result[:messages][0][:line_number], :column => result[:messages][0][:column_number]  
          end
        rescue
          #ok with this exception
        end
        TextMate::UI.simple_notification({:title => "MavensMate", :summary => "Compile Failed", :log => parse_error_message(result)})
      end
    rescue Exception => e
      #alert e.message + "\n" + e.backtrace.join("\n")
      alert e.message
    end
  end
  
  #refreshes the selected file from the server
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
        
    begin
      deleting_what = (get_selected_files.length > 1) ? "Selected Metadata" : File.basename(ENV['TM_FILEPATH'])
      TextMate.call_with_progress( :title => "MavensMate", :message => "Deleting #{deleting_what}" ) do
        zip_file = MavensMate::FileFactory.put_delete_metadata(get_metadata_hash)     
        client = MavensMate::Client.new
        result = client.deploy({:zip_file => zip_file})
        if ! result[:is_success]        
          TextMate.go_to :file => ENV['TM_FILEPATH'], :line => result[:line_number], :column => result[:column_number]  
          TextMate::UI.alert(:warning, "Delete Failed", get_error_message(result))
        else
          get_selected_files.each do |f|
            FileUtils.rm_r f   
          end
          TextMate.rescan_project
        end
      end
    rescue Exception => e
      alert e.message
    end
  end
  
  #compiles entire project
  def self.compile_project    
    validate [:internet, :mm_project]
    
    begin
      TextMate.call_with_progress( :title => 'MavensMate', :message => 'Compiling Project' ) do
        zip_file = MavensMate::FileFactory.copy_project_to_tmp 
        client = MavensMate::Client.new
        result = client.deploy({:zip_file => zip_file}) 
        if ! result[:is_success]        
          TextMate::UI.alert(:warning, "Compile Failed", get_error_message(result))
        end
      end
    rescue Exception => e
      alert e.message
    end
  end
        
  #wipes local project and rewrites with server copies based on current project's package.xml, preserves svn/git      
  def self.clean_project    
    validate [:internet, :mm_project]
       
    confirmed = TextMate::UI.request_confirmation(
      :title => "Salesforce Project Cleaner",
      :prompt => "Your Salesforce project will be emptied and refreshed according to package.xml. Any local metadata (not on the Salesforce.com server) will be lost forever.",
      :button1 => "Clean")
    
    begin
      if confirmed
        TextMate.call_with_progress( :title => "MavensMate", :message => "Cleaning Project" ) do
          pd = ENV['TM_PROJECT_DIRECTORY']
          Dir.foreach("#{pd}/src") do |entry| #iterate the metadata folders
            next if entry.include? "."
            Dir.foreach("#{pd}/src/#{entry}") do |subentry| #iterate the files inside those folders
              next if subentry == '.' || subentry == '..' || subentry == '.svn' || subentry == '.git'
              FileUtils.rm_r "#{pd}/src/#{entry}/#{subentry}"
            end
          end
          require 'fileutils'   
          FileUtils.rm_r "#{pd}/config/objects" if File.directory? "#{pd}/config/objects"
          
          client = MavensMate::Client.new
          project_zip = client.retrieve({ :package => "#{ENV['TM_PROJECT_DIRECTORY']}/src/package.xml" })
          MavensMate::FileFactory.finish_clean(get_project_name, project_zip) #put the metadata in the project directory 
          
          #put object metadata
          object_response = client.list("CustomObject", true)
          object_list = []
          object_response[:list_metadata_response][:result].each do |obj|
            object_list.push(obj[:full_name])
          end 
          object_hash = { "CustomObject" => object_list }               
          options = { :meta_types => object_hash }
          object_zip = client.retrieve(options) #get selected metadata
          MavensMate::FileFactory.put_object_metadata(get_project_name, object_zip)
                 
          TextMate.rescan_project
        end
      end
    rescue Exception => e
      alert e.message
      #alert e.message + "\n" + e.backtrace.join("\n")
    end
    
  end
    
  #deploys project metadata to a salesforce.com server
  def self.deploy_to_server(params)
    validate [:internet, :mm_project]
    
    begin
      puts '<div id="mm_logger">'
      TextMate.call_with_progress( :title => "MavensMate", :message => "Deploying to the server") do
        endpoint = (params[:server_url].include? "test") ? "https://test.salesforce.com/services/Soap/u/#{MM_API_VERSION}" : "https://www.salesforce.com/services/Soap/u/#{MM_API_VERSION}"
        zip_file = MavensMate::FileFactory.put_tmp_metadata(params[:selected_types])     
        client = MavensMate::Client.new({ :username => params[:un], :password => params[:pw], :endpoint => endpoint })
        result = client.deploy({:zip_file => zip_file, :deploy_options => "<checkOnly>#{params[:check_only]}</checkOnly><rollbackOnError>true</rollbackOnError>"})
        puts "</div>"
        return result
        # if ! result[:is_success]        
        #   TextMate.go_to :file => ENV['TM_FILEPATH'], :line => result[:line_number], :column => result[:column_number]  
        #   TextMate::UI.alert(:warning, "Compile Failed", get_error_message(result))
        # end
      end
    rescue Exception => e
      #alert e.message + "\n" + e.backtrace.join("\n")
      puts "</div>"
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
     
  #displays autocomplete dialog based on current word. supports object fields & apex primitive methods
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
  
  #TODO 
  def self.describe

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
    
    #parses and returns error message in friendly format
    def self.parse_error_message(result)
      full_message = ""
      if result[:messages] && result[:messages].size > 0
        result[:messages].each { |message|
          next if message[:file_name].include? "package.xml"
          file_name_array = message[:file_name].split('/')
          file_name = file_name_array[file_name_array.length - 1]
          error_message = "#{file_name}\nError: #{message[:problem]}"
          line_message = ""
          column_message = ""
          if ! message[:line_number].nil?
            line_message << "\nLine: #{message[:line_number]}"
          end
          if ! message[:column_number].nil?
            column_message << "\nColumn: #{message[:column_number]}"
          end       
          full_message << error_message + line_message + column_message
        }
      end
      if result[:failures] && result[:failures].size > 0
        result[:failures].each { |failure|
          #full_message << "#{failure.inspect}\n\n"
          full_message << "#{failure[:name]}\n#{failure[:message]}\n#{failure[:stack_trace]}\n\n"
        }
      end
      return full_message
    end
    
    #parses and returns error message in friendly format
    def self.get_error_message(result)
      file_name_array = result[:file_name].split('/')
      file_name = file_name_array[file_name_array.length - 1]
      error_message = "#{file_name}\n#{result[:error_message]}"
      line_message = ""
      column_message = ""
      if ! result[:line_number].nil?
        line_message << "\nLine: #{result[:line_number]}"
      end
      if ! result[:column_number].nil?
        column_message << "\nColumn: #{result[:column_number]}"
      end
      return error_message + line_message + column_message
    end
    
    #returns metadata hash of selected files
    def self.get_metadata_hash(active_file=false)
      selected_files = get_selected_files(active_file)     
      meta_hash = {}
      selected_files.each do |f|
        puts "selected file: " + f + "<br/>"
        next if ! f.include? "." #need files only, not directories
        next if f.include? "-meta.xml" #dont need meta files
        ext = File.extname(f) #=> .cls
        ext_no_period = File.extname(f).gsub(".","") #=> cls
        puts "ext_no_period: " + ext_no_period + "<br/>"
        mt_hash = MavensMate::FileFactory.get_meta_type_by_suffix(ext_no_period)      
        meta_type = mt_hash[:xml_name]
        puts "meta_type: " + meta_type.inspect + "<br/>"

        if ! meta_hash.key? meta_type #key isn't there yet, put it in        
          meta_hash[meta_type] = [File.basename(f, ext)] #file name with no extension
        else #key is there, let's add metadata to it
          meta_array = meta_hash[meta_type] #get the existing array
          meta_array.push(File.basename(f, ext)) #add the new piece of metadata
          meta_hash[meta_type] = meta_array #replace the key
        end 
      end
      
      puts "hash is: "+meta_hash.inspect
      return meta_hash
    end
        
    #returns array of selected files
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
          return selected_files
        rescue
          return Array[ENV['TM_FILEPATH']]
        end
      end
    end
        
    #adds salesforce.com creds to the keychain
    def self.add_to_keychain(project_name, pw)
      TextMate::Process.run("security add-generic-password -a '#{project_name}-mm' -s \"MavensMate: #{project_name}\" -w #{pw} -U", :interactive_input => false) do |str|
      		STDOUT << htmlize(str, :no_newline_after_br => true)
      end
    end
    
    #opens project in textmate
    def self.open_project(project_name)
      project_folder = get_project_folder
      Dir.chdir("#{project_folder}")
      TextMate::Process.run("find . -type d -name '#{project_name}' -exec mate {} \\;", :interactive_input => false) do |str|
        STDOUT << htmlize(str, :no_newline_after_br => true)
      end
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
        TCPSocket.new 'google.com', 80 
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
    
    #returns the project name
    def self.get_project_name
      yml = YAML::load(File.open(ENV['TM_PROJECT_DIRECTORY'] + "/config/settings.yaml"))
      project_name = yml['project_name']
    end
end