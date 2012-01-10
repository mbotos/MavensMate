require 'rubygems'
require 'savon'
require 'httpi'
require 'fileutils'
require 'base64'
require 'yaml'
require 'json'
require BUNDLESUPPORT + '/lib/factory'
require BUNDLESUPPORT + '/lib/keychain'
require BUNDLESUPPORT + '/lib/metadata_helper'

module MavensMate
  
  class Client 
    
    include MetadataHelper
    PACKAGE_TYPES = [ "ApexClass", "ApexComponent", "ApexPage", "ApexTrigger", "StaticResource" ]
    
    # sfdc username
    attr_accessor :username
    # sfdc password
    attr_accessor :password
    # partner endpoint
    attr_accessor :endpoint
    # partner client
    attr_accessor :pclient
    # metadata client
    attr_accessor :mclient
    # session id
    attr_accessor :sid
    # metadata api endpoint url
    attr_accessor :metadata_server_url
           
    def initialize(creds={})
      HTTPI.log = false
      Savon.configure do |config|
        config.log = false
      end      
      if creds[:sid].nil? && creds[:metadata_server_url].nil?        
        creds = (creds[:username].nil? || creds[:password].nil? || creds[:endpoint].nil?) ? get_creds : creds
        self.username = creds[:username]
        self.password = creds[:password]
        if ! creds[:endpoint].include? "Soap"
          creds[:endpoint] = (creds[:endpoint].include? "test") ? "https://test.salesforce.com/services/Soap/u/#{MM_API_VERSION}" : "https://www.salesforce.com/services/Soap/u/#{MM_API_VERSION}"
        end
        self.endpoint = creds[:endpoint] 
        self.pclient = get_partner_client
        login
      else
        self.sid = creds[:sid]
        self.metadata_server_url = creds[:metadata_server_url]
      end
    end
    
    #logs into SFDC, sets metadata server url & sessionid
    def login
      begin
        response = self.pclient.request :login do
          soap.body = { :username => self.username, :password => self.password }
        end
      rescue Savon::SOAP::Fault => fault
        raise Exception.new(fault.to_s)
      end
      
      res = response.to_hash
      self.metadata_server_url = res[:login_response][:result][:metadata_server_url]
      self.sid = res[:login_response][:result][:session_id].to_s
    end
    
    #retrieves metadata in zip format. :path => retrieve specific file  
    def retrieve(options={})
      self.mclient = get_metadata_client
          
      begin
        response = mclient.request :retrieve do |soap|
          soap.header = get_soap_header
          soap.body = get_retrieve_body(options)                       
        end
      rescue Savon::SOAP::Fault => fault
        raise Exception.new(fault.to_s)
      end
      
      retrieve_hash = response.to_hash
      retrieve_id = retrieve_hash[:retrieve_response][:result][:id]
      
      is_finished = false
      while is_finished == false
        sleep 2
        response = self.mclient.request :check_status do |soap|
          soap.header = get_soap_header  
          soap.body = { :id => retrieve_id  }
        end
        status_hash = response.to_hash
        puts "<br/>status is: " + status_hash.inspect
        is_finished = status_hash[:check_status_response][:result][:done]
      end
      
      begin
        retrieve_response = self.mclient.request :check_retrieve_status do |soap|
          soap.header = get_soap_header 
          soap.body = { :id => retrieve_id  }
        end
      rescue Savon::SOAP::Fault => fault
        raise Exception.new(fault.to_s)
      end
      
      retrieve_request_hash = retrieve_response.body
      zip_file = retrieve_request_hash[:check_retrieve_status_response][:result][:zip_file]
    end
    
    #deploy/delete base64 encoded metadata to salesforce    
    def deploy(options={})
      self.mclient = get_metadata_client      
      soapbody = "<zipFile>#{options[:zip_file]}</zipFile>"
      soapbody << "<DeployOptions>#{options[:deploy_options]}</DeployOptions>" unless options[:deploy_options].nil?
      begin
        response = self.mclient.request :deploy do |soap|
          soap.header = get_soap_header
          soap.body = soapbody
        end
        puts "<br/><br/> deploy response: " + response.inspect
        create_hash = response.to_hash
      rescue Savon::SOAP::Fault => fault
        raise Exception.new(fault.to_s)
      end
            
      update_id = create_hash[:deploy_response][:result][:id]
      is_finished = false

      while ! is_finished
        sleep 1
        response = self.mclient.request :check_status do |soap|
          soap.header = get_soap_header
          soap.body = { :id => update_id  }
        end
        check_status_hash = response.to_hash
        #puts "<br/><br/>status is: " + check_status_hash.inspect + "<br/><br/>"
        is_finished = check_status_hash[:check_status_response][:result][:done]         
      end
            
      response = self.mclient.request :check_deploy_status do |soap|
        soap.header = get_soap_header
        soap.body = { :id => update_id  }
      end
      
      status_hash = response.to_hash
      puts "<br/><br/>deploy result is: " + status_hash.inspect + "<br/><br/>"
      
      #return full response on a test run
      if options[:deploy_options] and options[:deploy_options].include? "runTests"
        return status_hash
      end
      
      #tests have failed preventing a successful deployment
      if status_hash[:check_deploy_status_response][:result][:success] == false
        failures = []
        messages = []
        if status_hash[:check_deploy_status_response][:result][:run_test_result][:failures]
          if ! status_hash[:check_deploy_status_response][:result][:run_test_result][:failures].kind_of? Array
            failures.push(status_hash[:check_deploy_status_response][:result][:run_test_result][:failures])
          else
            failures = status_hash[:check_deploy_status_response][:result][:run_test_result][:failures]
          end
        end
        if status_hash[:check_deploy_status_response][:result][:messages]
          if ! status_hash[:check_deploy_status_response][:result][:messages].kind_of? Array
            messages.push(status_hash[:check_deploy_status_response][:result][:messages])
          else
            messages = status_hash[:check_deploy_status_response][:result][:messages]
          end
        end
        return { 
          :is_success => false,
          :failures => failures,
          :messages => messages
        }
      end
      
      #deployment is "successful", but there are compile issues with the metadata
      if status_hash[:check_deploy_status_response][:result][:messages].kind_of? Array
        status_hash[:check_deploy_status_response][:result][:messages].each { |message| 
          if ! message[:success]
            return { 
               :is_success => message[:success],
               :line_number => message[:line_number],
               :column_number => message[:column_number],
               :error_message => message[:problem],
               :file_name => message[:file_name]
             }
          end           
        }
        return { 
          :is_success => status_hash[:check_deploy_status_response][:result][:messages][0][:success],
          :line_number => status_hash[:check_deploy_status_response][:result][:messages][0][:line_number],
          :column_number => status_hash[:check_deploy_status_response][:result][:messages][0][:column_number],
          :error_message => status_hash[:check_deploy_status_response][:result][:messages][0][:problem],
          :file_name => status_hash[:check_deploy_status_response][:result][:messages][0][:file_name]
        }
      else
        if ! status_hash[:check_deploy_status_response][:result][:messages][:success]       
          return { 
             :is_success => status_hash[:check_deploy_status_response][:result][:messages][:success],
             :line_number => status_hash[:check_deploy_status_response][:result][:messages][:line_number],
             :column_number => status_hash[:check_deploy_status_response][:result][:messages][:column_number],
             :error_message => status_hash[:check_deploy_status_response][:result][:messages][:problem],
             :file_name => status_hash[:check_deploy_status_response][:result][:messages][:file_name]
           }
         else          
           return { 
             :is_success => true,
             :done => true 
           } 
         end
      end
    end
    
    #describes an org's metadata
    def describe
      self.mclient = get_metadata_client
      begin
        response = self.mclient.request :describe_metadata do |soap|
          soap.header = get_soap_header  
          soap.body = "<apiVersion>#{MM_API_VERSION}</apiVersion>"
        end
      rescue Savon::SOAP::Fault => fault
        raise Exception.new(fault.to_s)
      end
      puts "<br/><br/> describe response: " + response.to_hash.inspect
      hash = response.to_hash
      folders = Array.new
      hash[:describe_metadata_response][:result][:metadata_objects].each { |object| 
        folders.push({
          :title => object[:directory_name],
          :isLazy => true,
          :isFolder => true,
          :directory_name => object[:directory_name],
          :meta_type => object[:xml_name],
          :select => PACKAGE_TYPES.include?(object[:xml_name]) ? true : false
        })
      }
      folders.sort! { |a,b| a[:title] <=> b[:title] }
      return folders.to_json
    end
    
    #list metadata for a specific type
    def list(type="",raw=false)
      self.mclient = get_metadata_client
      begin
        response = self.mclient.request :list_metadata do |soap|
          soap.header = get_soap_header  
          soap.body = "<ListMetadataQuery><type>#{type}</type></ListMetadataQuery>"
        end
      rescue Savon::SOAP::Fault => fault
        raise Exception.new(fault.to_s)
      end
      begin
        return response unless ! raw
        hash = response.to_hash
        els = Array.new
        if hash[:list_metadata_response].nil?
          return "[]"
        elsif hash[:list_metadata_response][:result].kind_of? Hash
          els.push({
            :title => hash[:list_metadata_response][:result][:full_name],
            :key => hash[:list_metadata_response][:result][:full_name],
            :isLazy => true
          })  
          return els.to_json        
        else
          hash[:list_metadata_response][:result].each { |el| 
            els.push({
              :title => el[:full_name],
              :key => el[:full_name]
            })
          }
          els.sort! { |a,b| a[:title].downcase <=> b[:title].downcase }
          return els.to_json
        end
      rescue Exception => e
        return hash.inspect + "\n\n\n" + e.message + "\n" + e.backtrace.join("\n")
      end
    end
                                                            
    private
      
      #ensures json is properly formatted for the dynatree control
      def to_json(what)
        what.to_hash.to_json
      end
      
      #returns header for soap calls with valid sessionid
      def get_soap_header
        return { "ins0:SessionHeader" => { "ins0:sessionId" => self.sid } } 
      end
      
      #returns body for soap calls with requested metadata specified
      def get_retrieve_body(options)
        types_body = ""
        if ! options[:package].nil?
          require 'rexml/document'
          xml_data = File.read(options[:package])
          doc = REXML::Document.new(xml_data)
          types_body = ""
          doc.elements.each('Package/types') do |el|
            types_body << "<types>"
            types_body << "<name>#{el.elements["name"].text}</name>"
            el.each_element do |member|
              if member.to_s.include? "<members>"
                types_body << "<members>#{member.text}</members>"
              end
            end
            types_body << "</types>"
          end
          return "<RetrieveRequest><unpackaged>#{types_body}</unpackaged><apiVersion>#{MM_API_VERSION}</apiVersion></RetrieveRequest>"
        else        
          if ! options[:path].nil? #grab path only
            path = options[:path]
            ext = File.extname(path).gsub(".","") #=> "cls"
            mt = MavensMate::FileFactory.get_meta_type_by_suffix(ext)
            file_name_no_ext = File.basename(path, File.extname(path)) #=> "myclass" 
            types_body << "<types><members>#{file_name_no_ext}</members><name>#{mt[:xml_name]}</name></types>"
          elsif ! options[:meta_types].nil? #custom built project	
      			options[:meta_types].each { |meta_type, selected_children| 
      			    types_body << "<types>"
      			    if selected_children.length == 0
      			      types_body << "<members>*</members>"
      			    else
      			      selected_children.each { |child|  
        			      types_body << "<members>#{child}</members>"
      			      }
      			    end
      			    types_body << "<name>"+meta_type+"</name>"
      			    types_body << "</types>"
      			}    			
          else #grab from default package
            PACKAGE_TYPES.each { |type|  
              types_body << "<types><members>*</members><name>"+type+"</name></types>"
            }
          end     
          return "<RetrieveRequest><unpackaged>#{types_body}</unpackaged><apiVersion>#{MM_API_VERSION}</apiVersion></RetrieveRequest>"
        end
      end
      
      #returns salesforce credentials from keychain
      def get_creds 
        yml = YAML::load(File.open(ENV['TM_PROJECT_DIRECTORY'] + "/config/settings.yaml"))
        project_name = yml['project_name']
        username = yml['username']
        environment = yml['environment']
        password = KeyChain::find_internet_password("#{project_name}-mm")
        endpoint = environment == "sandbox" ? "https://test.salesforce.com/services/Soap/u/#{MM_API_VERSION}" : "https://www.salesforce.com/services/Soap/u/#{MM_API_VERSION}"
        return { :username => username, :password => password, :endpoint => endpoint }
      end
      
      #returns partner connection
      def get_partner_client
        client = Savon::Client.new do
          wsdl.document = File.expand_path(ENV['TM_BUNDLE_SUPPORT']+"/partner.xml", __FILE__)
        end
        client.wsdl.endpoint = self.endpoint
        return client
      end
      
      #returns metadata connection
      def get_metadata_client
        client = Savon::Client.new do
          wsdl.document = File.expand_path(ENV['TM_BUNDLE_SUPPORT']+"/metadata.xml", __FILE__)
        end
        client.wsdl.endpoint = self.metadata_server_url
        #puts "<br/><br/>METADATA CLIENT ACTIONS: #{client.wsdl.soap_actions}"
        return client
      end
  
  end
end