module MavensMate
  module FileFactory
       
      class << self
           
      require 'fileutils'     

      META_DIR_MAP = { "ApexClass" => "classes", "ApexComponent" => "components", "ApexPage" => "pages", "ApexTrigger" => "triggers", "StaticResource" => "staticResources" }
      META_EXT_MAP = { "ApexClass" => ".cls", "ApexComponent" => ".component", "ApexPage" => ".page", "ApexTrigger" => ".trigger", "StaticResource" => ".resource" }     
                    
      def put_local_metadata(options = { })
        api_name = options[:api_name]
        meta_type = options[:meta_type]
        object_name = options[:object_name]
               
        dir = ENV['TM_PROJECT_DIRECTORY'] + "/src/" + META_DIR_MAP[meta_type]
        if ! File.directory?(dir)
        	Dir.mkdir(dir)
        end
        Dir.chdir(dir)

        file_name = put_src_file(:api_name => api_name, :meta_type => meta_type, :object_name => object_name)
        put_meta_file(:api_name => api_name, :meta_type => meta_type, :object_name => object_name)
      end
    
      def destroy_local_metadata(options = { }) 
        api_name = options[:api_name]
        meta_type = options[:meta_type]
        FileUtils.rm_r ENV['TM_PROJECT_DIRECTORY'] + "/src/" + META_DIR_MAP[meta_type] + "/#{api_name}" + META_EXT_MAP[meta_type]
        FileUtils.rm_r ENV['TM_PROJECT_DIRECTORY'] + "/src/" + META_DIR_MAP[meta_type] + "/#{api_name}" + META_EXT_MAP[meta_type] + "-meta.xml"
      end
      
      private
      
      def put_src_file(options = { })
        api_name = options[:api_name]
        meta_type = options[:meta_type]
        object_name = options[:object_name]
        file_name = "#{api_name}" + META_EXT_MAP[meta_type]
        src = File.new(file_name, "w")
        case meta_type
          when "ApexClass"
            src.puts("public with sharing class #{api_name} {")
            src.puts("")
            src.puts("	public #{api_name}() {")
            src.puts("")
            src.puts("	}")
            src.puts("}")
          when "ApexComponent"
            src.puts("<apex:component>")
            src.puts("")
            src.puts("</apex:component>")           
          when "ApexPage"
            src.puts("<apex:page showHeader=\"true\" sidebar=\"true\">")
            src.puts("")
            src.puts("</apex:page>")
          when "ApexTrigger"
            src.puts("trigger #{api_name} on #{object_name} (before insert) {")
            src.puts("")
            src.puts("}")
        end
        src.close
        return file_name
      end
      
      def put_meta_file(options = { })
        api_name = options[:api_name]
        meta_type = options[:meta_type]
        object_name = options[:object_name]
        
        src_meta_file_name = api_name + META_EXT_MAP[meta_type] + "-meta.xml"
        src_meta = File.new(src_meta_file_name, "w")
        src_meta.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        src_meta.puts("<#{meta_type} xmlns=\"http://soap.sforce.com/2006/04/metadata\">")
        src_meta.puts("<apiVersion>22.0</apiVersion>")
        case meta_type
          when "ApexComponent"
            src_meta.puts("<label>#{api_name}</label>")
            src_meta.puts("<description>A visualforce component</description>")
          when "ApexPage"
            src_meta.puts("<label>#{api_name}</label>")
            src_meta.puts("<description>A visualforce component</description>")
          when "ApexTrigger"
            src_meta.puts("<status>Active</status>")
        end
        src_meta.puts("</#{meta_type}>")
        src_meta.close
      end
      end   
  end
end