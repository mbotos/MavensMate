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
require BUNDLESUPPORT + '/lib/ui'

STDOUT.sync = true

TM_ANT = (ENV['TM_ANT'] == nil) ? 'ant' : ENV['TM_ANT']

TextMate.require_cmd "#{TM_ANT}"
TextMate.min_support 10895

module MavensMate
  
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
      	Dir.foreach("#{pd}") do |entry|
           FileUtils.rm_r "#{pd}/#{entry}" unless entry.include? "."
        end 
        TextMate.rescan_project
        ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'
      	TextMate::Process.run("ant -buildfile '#{ant_build_file}' retrieve", :interactive_input => false) do |str|
        		STDOUT << htmlize(str, :no_newline_after_br => true)
      	end
      	TextMate.rescan_project
      end 
      puts "<script type\"text/javascript\">setTimeout(close(),250000);</script>"   
    else
      TextMate.exit_discard
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
    class_name = TextMate::UI.request_string(
      :title => "ForceMate | New Apex Class",
      :prompt => "Class Name:")  

    cls_directory = ENV['TM_PROJECT_DIRECTORY'] + "/classes"
    if ! File.directory?(cls_directory)
    	Dir.mkdir(cls_directory)
    end
    Dir.chdir(cls_directory)

    cls = File.new("#{class_name}.cls", "w")
    cls.puts("public with sharing class #{class_name} {")
    cls.puts("")
    cls.puts("	public #{class_name}() {")
    cls.puts("")
    cls.puts("	}")
    cls.puts("}")
    cls.close

    cls_meta = File.new("#{class_name}.cls-meta.xml", "w")
    cls_meta.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    cls_meta.puts("<ApexClass xmlns=\"http://soap.sforce.com/2006/04/metadata\">")
    cls_meta.puts("<apiVersion>22.0</apiVersion>")
    cls_meta.puts("</ApexClass>")
    cls_meta.close 

    ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'

    TextMate::Process.run("ant -buildfile '#{ant_build_file}' deploy", :interactive_input => false) do |str|
      STDOUT << htmlize(str, :no_newline_after_br => true)
    end

    TextMate.rescan_project 
    TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/classes/#{class_name}.cls"
  end
  
  def self.new_apex_trigger
    object_name = TextMate::UI.request_string(
      :title => "ForceMate | New Apex Trigger",
      :prompt => "Object API Name:")  

    trigger_name = TextMate::UI.request_string(
      :title => "ForceMate | New Apex Trigger",
      :prompt => "Trigger Name:")  

    trigger_directory = ENV['TM_PROJECT_DIRECTORY'] + "/triggers"
    if ! File.directory?(trigger_directory)
    	Dir.mkdir(trigger_directory)
    end
    Dir.chdir(trigger_directory)

    tgr = File.new("#{trigger_name}.trigger", "w")
    tgr.puts("trigger #{trigger_name} on #{object_name} (before insert) {")
    tgr.puts("")
    tgr.puts("}")
    tgr.close

    tgr_meta = File.new("#{trigger_name}.trigger-meta.xml", "w")
    tgr_meta.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    tgr_meta.puts("<ApexTrigger xmlns=\"http://soap.sforce.com/2006/04/metadata\">")
    tgr_meta.puts("<apiVersion>22.0</apiVersion>")
    tgr_meta.puts("<status>Active</status>")
    tgr_meta.puts("</ApexTrigger>")
    tgr_meta.close

    tm_ant = 'ant' 
    tm_ant = (ENV['TM_ANT'] == nil) ? 'ant' : ENV['TM_ANT']

    ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'

    TextMate::Process.run("ant -buildfile '#{ant_build_file}' deploy", :interactive_input => false) do |str|
      STDOUT << htmlize(str, :no_newline_after_br => true)
    end

    TextMate.rescan_project
    TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/triggers/#{trigger_name}.trigger"    
  end
  
  def self.new_vf_page
    page_name = TextMate::UI.request_string(
      :title => "ForceMate | New Visualforce Page",
      :prompt => "Page Name:")  

    pages_directory = ENV['TM_PROJECT_DIRECTORY'] + "/pages"
    if ! File.directory?(pages_directory)
    	Dir.mkdir(pages_directory)
    end
    Dir.chdir(pages_directory)

    page = File.new("#{page_name}.page", "w")
    page.puts("<apex:page showHeader=\"true\" sidebar=\"true\">")
    page.puts("")
    page.puts("</apex:page>")
    page.close

    page_meta = File.new("#{page_name}.page-meta.xml", "w")
    page_meta.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    page_meta.puts("<ApexPage xmlns=\"http://soap.sforce.com/2006/04/metadata\">")
    page_meta.puts("<label>#{page_name}</label>")
    page_meta.puts("<description>A visualforce page</description>")
    page_meta.puts("<apiVersion>22.0</apiVersion>")
    page_meta.puts("</ApexPage>")
    page_meta.close

    tm_ant = 'ant' 
    tm_ant = (ENV['TM_ANT'] == nil) ? 'ant' : ENV['TM_ANT']

    ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'

    TextMate::Process.run("ant -buildfile '#{ant_build_file}' deploy", :interactive_input => false) do |str|
      STDOUT << htmlize(str, :no_newline_after_br => true)
    end

    TextMate.rescan_project 
    TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/pages/#{page_name}.page"
  end
  
  def self.new_vf_component
    comp_name = TextMate::UI.request_string(
      :title => "ForceMate | New Visualforce Component",
      :prompt => "Component Name:")  

    comps_directory = ENV['TM_PROJECT_DIRECTORY'] + "/components"
    if ! File.directory?(comps_directory)
    	Dir.mkdir(comps_directory)
    end
    Dir.chdir(comps_directory)

    comp = File.new("#{comp_name}.component", "w")
    comp.puts("<apex:component>")
    comp.puts("")
    comp.puts("</apex:component>")
    comp.close

    comp_meta = File.new("#{comp_name}.component-meta.xml", "w")
    comp_meta.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    comp_meta.puts("<ApexComponent xmlns=\"http://soap.sforce.com/2006/04/metadata\">")
    comp_meta.puts("<label>#{comp_name}</label>")
    comp_meta.puts("<description>A visualforce component</description>")
    comp_meta.puts("<apiVersion>22.0</apiVersion>")
    comp_meta.puts("</ApexComponent>")
    comp_meta.close

    tm_ant = 'ant' 
    tm_ant = (ENV['TM_ANT'] == nil) ? 'ant' : ENV['TM_ANT']

    ant_build_file = ENV['TM_PROJECT_DIRECTORY'] + '/build.xml'

    TextMate::Process.run("ant -buildfile '#{ant_build_file}' deploy", :interactive_input => false) do |str|
      STDOUT << htmlize(str, :no_newline_after_br => true)
    end

    TextMate.rescan_project 
    TextMate.go_to :file => ENV['TM_PROJECT_DIRECTORY'] + "/components/#{comp_name}.component"
  end
  
end