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

require BUNDLESUPPORT + '/lib/client'
require BUNDLESUPPORT + '/lib/factory'
require BUNDLESUPPORT + '/lib/ui'
require BUNDLESUPPORT + '/lib/exceptions'

STDOUT.sync = true

TM_ANT = (ENV['TM_ANT'] == nil) ? 'ant' : ENV['TM_ANT']

TextMate.require_cmd "#{TM_ANT}"
TextMate.min_support 10895

module MavensMate
  
  def self.describe
    #TODO: Finish
    ant_build_file = "" 
    ant_build_file = BUNDLESUPPORT + '/build.xml'
    
    TextMate.call_with_progress( :title => 'SVN Connection', :message => 'Checking out from Repository' ) do
  		#describe org
  		Dir.chdir("#{project_folder}/#{projectName}")
  		TextMate.call_with_progress( :title => 'New Project', :message => 'Retrieving Metadata' ) do
        TextMate::Process.run("ant -buildfile '#{ant_build_file}' describe", :interactive_input => false) do |str|
          		STDOUT << htmlize(str, :no_newline_after_br => true)
        	end
        end
  	end    
  end
  
  def self.delete_metadata
    #TODO
  end
  
  
  def self.checkout_project
    project_folder = ENV['FM_PROJECT_FOLDER']
    project_folder +='/' unless project_folder.end_with?("/")

    puts html_head( :window_title => "Checkout Salesforce Project", :page_title => "Salesforce.com Checkout Wizard" );

    d = MavensMate::UI.new_project_dialog
    un = d['sfdc_un'];
    pw = d['sfdc_pw'];
    projectName = d['project_name']
    svn_un = d['svn_un']
    svn_pw = d['svn_pw']
    svn_url = d['svn_url']
    server_url = d['sfdc_server_url']

    if un.length == 0 || pw.length == 0 || projectName.length == 0 || server_url.length == 0
    	puts "ERROR: all fields are required"
    	abort
    end

    if svn_url.length == 0 || svn_un.length == 0 || svn_pw.length == 0
    	puts "ERROR: please specify svn information"
    	abort
    end
    
    Dir.mkdir(project_folder) unless File.exists?(project_folder)

    base_dir = ""
    ant_build_file = "" 
    ant_build_file = BUNDLESUPPORT + '/build.xml'

    if svn_url.length > 0 && svn_un.length > 0 && svn_pw.length > 0
    	TextMate.call_with_progress( :title => 'SVN Connection', :message => 'Checking out from Repository' ) do
    		#checkout project
    		Dir.mkdir("#{project_folder}/#{projectName}") unless File.exists?("#{project_folder}/#{projectName}")
    		Dir.chdir("#{project_folder}")	
    		TextMate::Process.run("svn checkout #{svn_url} '#{projectName}' --username #{svn_un} --password #{svn_pw}", :interactive_input => false) do |str|
      			STDOUT << htmlize(str, :no_newline_after_br => true)
    		end
    		#add force.com nature
    		TextMate::Process.run("ant -buildfile '#{ant_build_file}' -Dpd=#{project_folder} -Dun=#{un} -Dpw=#{pw} -Dpn='#{projectName}' -Dserverurl=#{server_url} checkoutProject", :interactive_input => false) do |str|
        		STDOUT << htmlize(str, :no_newline_after_br => true)
      	end
    	end
    end

    Dir.chdir("#{project_folder}")

    TextMate::Process.run("find . -type d -name '#{projectName}' -exec mate {} \\;", :interactive_input => false) do |str|
      STDOUT << htmlize(str, :no_newline_after_br => true)
    end
    puts "</pre>"
    puts "<script type\"text/javascript\">close();</script>"            
    TextMate.exit_show_html
  end
  
  def self.new_project
    project_folder = ENV['FM_PROJECT_FOLDER']
    project_folder +='/' unless project_folder.end_with?("/")

    puts html_head( :window_title => "New Salesforce Project", :page_title => "Salesforce.com Project Wizard" );

    d = MavensMate::UI.new_project_dialog
    un = d['sfdc_un'];
    pw = d['sfdc_pw'];
    projectName = d['project_name']
    svn_un = d['svn_un']
    svn_pw = d['svn_pw']
    svn_url = d['svn_url']
    server_url = d['sfdc_server_url']

    if un.length == 0 || pw.length == 0 || projectName.length == 0 || server_url.length == 0
    	puts "ERROR: all salesforce.com-related fields are required"
    	abort
    end

    Dir.mkdir(project_folder) unless File.exists?(project_folder)

    base_dir = ""
    ant_build_file = "" 
    ant_build_file = BUNDLESUPPORT + '/build.xml'

    if File.exists?( ant_build_file )
      source = REXML::Document.new( File.open( ant_build_file, "r"))
    end

    TextMate.call_with_progress( :title => 'New Project', :message => 'Retrieving Metadata' ) do
    	TextMate::Process.run("ant -buildfile '#{ant_build_file}' -Dpd=#{project_folder} -Dun=#{un} -Dpw=#{pw} -Dpn='#{projectName}' -Dserverurl=#{server_url} createProject", :interactive_input => false) do |str|
      		STDOUT << htmlize(str, :no_newline_after_br => true)
    	end
    end

    if svn_url.length > 0 && svn_un.length > 0 && svn_pw.length > 0
    	TextMate.call_with_progress( :title => 'SVN Connection', :message => 'Importing to Repository' ) do
    		Dir.chdir("#{project_folder}#{projectName}")	
    		TextMate::Process.run("svn import #{svn_url} --username #{svn_un} --password #{svn_pw} -m \"initial import\"", :interactive_input => false) do |str|
      			STDOUT << htmlize(str, :no_newline_after_br => true)
    		end
    	end
    	TextMate.call_with_progress( :title => 'SVN Connection', :message => 'Checking out from Repository' ) do
    		Dir.chdir("#{project_folder}")	
    		TextMate::Process.run("svn checkout --force #{svn_url}", :interactive_input => false) do |str|
      			STDOUT << htmlize(str, :no_newline_after_br => true)
    		end
    	end
    end

    Dir.chdir("#{project_folder}")

    TextMate::Process.run("find . -type d -name '#{projectName}' -exec mate {} \\;", :interactive_input => false) do |str|
      STDOUT << htmlize(str, :no_newline_after_br => true)
    end
    puts "</pre>"
    puts "<script type\"text/javascript\">close();</script>"            
    TextMate.exit_show_html
  end
  
  def self.compile_project
    puts html_head( :window_title => "Compiling Salesforce Project", :page_title => "" );
    ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'

    TextMate.call_with_progress( :title => 'Project Compile', :message => 'Compiling Project' ) do
    	TextMate::Process.run("ant -buildfile '#{ant_build_file}' deploy", :interactive_input => false) do |str|
      		STDOUT << htmlize(str, :no_newline_after_br => true)
    	end
    end
    #puts "<script type\"text/javascript\">close();</script>"    
  end
  
  #removes all files from project directory and replaces the,
  #with the latest from the server
  def self.clean_project
    confirmed = TextMate::UI.request_confirmation(
      :title => "Salesforce Project Cleaner",
      :prompt => "Your Salesforce project will be emptied and refreshed. Any local metadata (not on the Salesforce.com server) will be lost forever",
      :button1 => "Clean")
    
    if confirmed
      puts html_head( :window_title => "Salesforce Project Cleaner", :page_title => "Cleaning Salesforce Project" );
      TextMate.call_with_progress( :title => 'Project Clean', :message => 'Fetching Metadata' ) do
        require 'fileutils'
        pd = ENV['TM_PROJECT_DIRECTORY']
        Dir.foreach("#{pd}/src") do |entry| #iterate the metadata folders
          next if entry.include? "."
          Dir.foreach("#{pd}/src/#{entry}") do |subentry| #iterate the files inside those folders
            next if subentry == '.' || subentry == '..' || subentry == '.svn' || subentry == '.git'
            FileUtils.rm_r "#{pd}/src/#{entry}/#{subentry}"
          end
        end
        #end local cleanup
        #fetching server stuff
        TextMate.rescan_project
        ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'
        TextMate::Process.run("ant -buildfile '#{ant_build_file}' retrieve", :interactive_input => false) do |str|
        		STDOUT << htmlize(str, :no_newline_after_br => true)
        end
        TextMate.rescan_project
      end
    end
  end
  
  def self.refresh_project
    puts html_head( :window_title => "Refreshing Salesforce Project", :page_title => "Refresh Project from the Server" );
    ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'
    TextMate.call_with_progress( :title => 'Project Refresh', :message => 'Refreshing Project Metadata' ) do
    	TextMate::Process.run("ant -buildfile '#{ant_build_file}' retrieve", :interactive_input => false) do |str|
      		STDOUT << htmlize(str, :no_newline_after_br => true)
    	end
    end
    TextMate.rescan_project
  end
  
  def self.new_apex_class
    puts html_head( :window_title => "New Apex Class", :page_title => "New Apex Class" );
    class_name = TextMate::UI.request_string(
       :title => "MavensMate | New Apex Class",
       :prompt => "Class Name:")  

     TextMate.call_with_progress( :title => 'New Apex Class', :message => 'Compiling class' ) do
       MavensMate::FileFactory.put_local_metadata(:api_name => class_name, :meta_type => 'ApexClass', :object_name => '')
       ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'
       result = MavensMate::Client.deploy(ant_build_file)
       if (!result[:success])
         MavensMate::FileFactory.destroy_local_metadata(:api_name => class_name, :meta_type => 'ApexClass', :object_name => '')
         puts result[:message]
         abort
       end 
     end
     #MavensMate::UI.close_html_window 
     #TODO: would like to close the html window here, but cannot do so without introducing an odd bug  
     TextMate.rescan_project    
     TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/src/classes/#{class_name}.cls"
  end
  
  def self.new_apex_trigger 
    puts html_head( :window_title => "New Apex Trigger", :page_title => "New Apex Trigger" );
    object_name = TextMate::UI.request_string(
      :title => "ForceMate | New Apex Trigger",
      :prompt => "Object API Name:")  

    trigger_name = TextMate::UI.request_string(
      :title => "ForceMate | New Apex Trigger",
      :prompt => "Trigger Name:")  

    TextMate.call_with_progress( :title => 'New Apex Class', :message => 'Compiling trigger' ) do
      f = MavensMate::FileFactory.put_local_metadata(:api_name => trigger_name, :meta_type => 'ApexTrigger', :object_name => object_name)
      ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'
      result = MavensMate::Client.deploy(ant_build_file)
      if (!result[:success])
        MavensMate::FileFactory.destroy_local_metadata(:api_name => trigger_name, :meta_type => 'ApexTrigger', :object_name => object_name)
        puts result[:message]
        abort      
      end
    end 
    TextMate.rescan_project 
    TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/src/triggers/#{trigger_name}.trigger"     
  end
  
  def self.new_vf_page
    puts html_head( :window_title => "New Visualforce Page", :page_title => "New Visualforce Page" );
    page_name = TextMate::UI.request_string(
      :title => "ForceMate | New Visualforce Page",
      :prompt => "Page Name:")  

      TextMate.call_with_progress( :title => 'New Visualforce Page', :message => 'Compiling page' ) do
        f = MavensMate::FileFactory.put_local_metadata(:api_name => page_name, :meta_type => 'ApexPage', :object_name => '')
        ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'
        result = MavensMate::Client.deploy(ant_build_file)
        if (!result[:success])
          MavensMate::FileFactory.destroy_local_metadata(:api_name => page_name, :meta_type => 'ApexPage', :object_name => '')
          puts result[:message] 
          abort
        end
      end
      TextMate.rescan_project
      TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/src/pages/#{page_name}.page"
  end
  
  def self.new_vf_component
    puts html_head( :window_title => "New Visualforce Component", :page_title => "New Visualforce Component" );
    comp_name = TextMate::UI.request_string(
      :title => "ForceMate | New Visualforce Component",
      :prompt => "Component Name:")  

      TextMate.call_with_progress( :title => 'New Visualforce Component', :message => 'Compiling component' ) do
        f = MavensMate::FileFactory.put_local_metadata(:api_name => comp_name, :meta_type => 'ApexComponent', :object_name => '')
        ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'
        result = MavensMate::Client.deploy(ant_build_file)
        if (!result[:success])
          MavensMate::FileFactory.destroy_local_metadata(:api_name => comp_name, :meta_type => 'ApexComponent', :object_name => '')
          puts result[:message]
          abort
        end
      end
      TextMate.rescan_project
      TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/src/components/#{comp_name}.component"
  end
  
end