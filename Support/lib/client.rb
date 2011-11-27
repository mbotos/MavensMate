require 'rubygems'
require 'savon'
require 'fileutils'
require 'base64'
require 'yaml'
require BUNDLESUPPORT + '/lib/factory'
require BUNDLESUPPORT + '/lib/keychain'
require BUNDLESUPPORT + '/lib/metadata_helper'

module MavensMate
  
  class Client 
    
    include MetadataHelper
    PACKAGE_TYPES = [ "ApexClass", "ApexComponent", "ApexPage", "ApexTrigger" ]
    
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
    attr_reader :sid
    # metadata api endpoint url
    attr_reader :metadata_server_url
           
    def initialize(creds={})
      Savon.configure do |config|
        config.log = false
      end      
      creds = (creds[:username].nil? || creds[:password].nil? || creds[:endpoint].nil?) ? get_creds : creds
      self.username = creds[:username]
      self.password = creds[:password]
      self.endpoint = creds[:endpoint] 
      self.pclient = get_partner_client
      login
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
      @metadata_server_url = res[:login_response][:result][:metadata_server_url]
      @sid = res[:login_response][:result][:session_id].to_s
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
    def deploy(base64Resource)
      self.mclient = get_metadata_client
      begin
        response = self.mclient.request :deploy do |soap|
          soap.header = get_soap_header
          soap.body = '<zipFile>'+base64Resource+'</zipFile>'
        end
      rescue Savon::SOAP::Fault => fault
        raise Exception.new(fault.to_s)
      end
      
      puts "<br/><br/> deploy response: " + response.to_hash.inspect
      create_hash = response.to_hash

      update_id = create_hash[:deploy_response][:result][:id]
      is_finished = false

      while ! is_finished
        sleep 2
        response = self.mclient.request :check_status do |soap|
          soap.header = get_soap_header
          soap.body = { :id => update_id  }
        end
        check_status_hash = response.to_hash
        puts "<br/><br/>status is: " + check_status_hash.inspect + "<br/><br/>"
        is_finished = check_status_hash[:check_status_response][:result][:done]         
      end
            
      response = self.mclient.request :check_deploy_status do |soap|
        soap.header = get_soap_header
        soap.body = { :id => update_id  }
      end
      
      status_hash = response.to_hash
      puts "<br/><br/>deploy status is: " + status_hash.inspect + "<br/><br/>"
      
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
                                                            
    private
      
      #returns header for soap calls with valid sessionid
      def get_soap_header
        return { "ins0:SessionHeader" => { "ins0:sessionId" => @sid } } 
      end
      
      #returns body for soap calls with requested metadata specified
      def get_retrieve_body(options)
        types_body = ""        
        if options[:path].nil? #grab all
          PACKAGE_TYPES.each { |type|  
            types_body << "<types><members>*</members><name>"+type+"</name></types>"
          }
        else #grab selected file
          path = options[:path]
          ext = File.extname(path) #=> ".cls"
          file_name_no_ext = File.basename(path, ext) #=> "myclass"
          types_body << "<types><members>#{file_name_no_ext}</members><name>#{EXT_META_MAP[ext]}</name></types>"
        end     
        return "<RetrieveRequest><unpackaged>#{types_body}</unpackaged><apiVersion>#{MM_API_VERSION}</apiVersion></RetrieveRequest>"
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
        client.wsdl.endpoint = @metadata_server_url
        #puts "<br/><br/>METADATA CLIENT ACTIONS: #{client.wsdl.soap_actions}"
        return client
      end
  
  end
end