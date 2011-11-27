require 'rubygems'    
require 'zip/zipfilesystem'
require 'fileutils'   
require 'tmpdir'
require 'base64'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/metadata_helper.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/environment.rb'
require 'erb'

module MavensMate
  module FileFactory
       
      class << self
      
      include MetadataHelper
      
      def put_project_config(username, project_name, server_url)
        project_folder = ENV['FM_PROJECT_FOLDER']
        project_folder +='/' unless project_folder.end_with?("/")
        Dir.mkdir(project_folder+project_name+"/config") unless File.exists?(project_folder+project_name+"/config")
        Dir.chdir(project_folder+project_name+"/config")
        file_name = "settings.yaml"
        if ! File.exists?(project_folder+project_name+"/config/settings.yaml")
          src = File.new(file_name, "w")
          src.puts("project_name: " + project_name)
          src.puts("username: " + username)
          environment = (server_url.include? "test") ? "sandbox" : "production"           
          src.puts("environment: " + environment)
          src.close
        else
          src = File.open(file_name, "w") 
          src.puts("project_name: " + project_name)
          src.puts("username: " + username)
          environment = (server_url.include? "test") ? "sandbox" : "production"           
          src.puts("environment: " + environment)
          src.close
        end
      end
      
      def put_project_directory(project_name)
        project_folder = ENV['FM_PROJECT_FOLDER']
        project_folder +='/' unless project_folder.end_with?("/")
        Dir.mkdir(project_folder) unless File.exists?(project_folder)
        Dir.mkdir(project_folder+"/"+project_name)
      end
      
      def put_project_metadata(project_name, project_zip)
        project_folder = ENV['FM_PROJECT_FOLDER']
        Dir.chdir(project_folder+"/"+project_name)
        File.open('metadata.zip', 'wb') {|f| f.write(Base64.decode64(project_zip))}
        Zip::ZipFile.open('metadata.zip') { |zip_file|
            zip_file.each { |f|
              f_path=File.join(project_folder+"/"+project_name, f.name)
              FileUtils.mkdir_p(File.dirname(f_path))
              zip_file.extract(f, f_path) unless File.exist?(f_path)
            }
          }
        FileUtils.rm_r project_folder+"/"+project_name+"/metadata.zip"
        FileUtils.mv project_folder+"/"+project_name+"/unpackaged", project_folder+"/"+project_name+"/src"        
      end
      
      def replace_file(file_path, project_zip)
        Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
        File.open('metadata.zip', 'wb') {|f| f.write(Base64.decode64(project_zip))}
        Zip::ZipFile.open('metadata.zip') { |zip_file|
           zip_file.each { |f|
             f_path=File.join(ENV['TM_PROJECT_DIRECTORY'], f.name)
             FileUtils.mkdir_p(File.dirname(f_path))
             zip_file.extract(f, f_path) unless File.exist?(f_path)
           }
         }
         Dir.chdir("#{ENV['TM_PROJECT_DIRECTORY']}/unpackaged")
         meta_type_ext = File.extname(file_path) #=> ".cls"
         meta_type = EXT_META_MAP[meta_type_ext] #=> "ApexClass"
         meta_type_dir_name = META_DIR_MAP[meta_type] #=> "classes"
         copy_to_dir = "#{ENV['TM_PROJECT_DIRECTORY']}/src/#{meta_type_dir_name}" #=> "/Users/username/Projects/myproject/src/classes"
         TextMate::Process.run("cp -r '#{Dir.getwd}/#{meta_type_dir_name}/' '#{copy_to_dir}'", :interactive_input => false) do |str|
           STDOUT << htmlize(str, :no_newline_after_br => true)          
         end
         Dir.chdir("#{ENV['TM_PROJECT_DIRECTORY']}")
         FileUtils.rm_r "#{ENV['TM_PROJECT_DIRECTORY']}/unpackaged"
         FileUtils.rm_r "#{ENV['TM_PROJECT_DIRECTORY']}/metadata.zip"
      end
      
      def put_delete_metadata(hash)     
        cleanup_tmp        
        put_package(Dir.getwd, binding, true)
        put_empty_package(Dir.getwd)        
        return zip_tmp_directory
      end
            
      def put_tmp_metadata(hash)
        cleanup_tmp
        put_tmp_directories(hash)
        put_package(Dir.getwd, binding, false)
        put_files_in_tmp_directories(hash)
        return zip_tmp_directory                       
      end
             
      def copy_project_to_tmp
        tmp_dir = Dir.tmpdir
        FileUtils.rm_rf("#{tmp_dir}/mmzip")
        Dir.mkdir("#{tmp_dir}/mmzip")
        Dir.mkdir("#{tmp_dir}/mmzip/unpackaged")
        Dir.chdir("#{ENV['TM_PROJECT_DIRECTORY']}/src")
        unpackaged_dir = "#{tmp_dir}/mmzip/unpackaged"
        TextMate::Process.run("cp -r * #{unpackaged_dir}", :interactive_input => false) do |str|
          STDOUT << htmlize(str, :no_newline_after_br => true)          
        end
        return zip_tmp_directory
      end 
       
      #puts metadata in a specified directory
      #if [:dir] is nil, it's assumed you want to put it in the project folder              
      def put_local_metadata(options = { })
        api_name    = options[:api_name]
        meta_type   = options[:meta_type]
        object_name = options[:object_name]        
        dir         = options[:dir]
        
        if dir.nil?       
          dir = ENV['TM_PROJECT_DIRECTORY'] + "/src/" + META_DIR_MAP[meta_type]
          if ! File.directory?(dir)
        	  Dir.mkdir(dir)
          end
          Dir.chdir(dir)
        elsif dir == "tmp"
          tmp_dir = Dir.tmpdir
          FileUtils.rm_rf("#{tmp_dir}/mmzip")
          Dir.mkdir("#{tmp_dir}/mmzip")
          Dir.mkdir("#{tmp_dir}/mmzip/unpackaged")
          Dir.mkdir("#{tmp_dir}/mmzip/unpackaged/"+META_DIR_MAP[meta_type])
          Dir.chdir("#{tmp_dir}/mmzip/unpackaged/"+META_DIR_MAP[meta_type])
        else
          Dir.chdir(dir)
        end

        file_name = put_src_file(:api_name => api_name, :meta_type => meta_type, :object_name => object_name)
        put_meta_file(:api_name => api_name, :meta_type => meta_type, :object_name => object_name)
        
        if ! options[:dir].nil?
          Dir.chdir('..')
          put_new_package(Dir.getwd, binding, false)
        end
        
        if dir == "tmp"
          Dir.chdir("#{tmp_dir}/mmzip")
          path = "#{tmp_dir}/mmzip"

          Zip::ZipFile.open("deploy.zip", 'w') do |zipfile|
            Dir["#{path}/**/**"].each do |file|
              zipfile.add(file.sub(path+'/',''),file)
            end
          end

          Dir.chdir("#{tmp_dir}/mmzip")
          file_contents = File.read("deploy.zip")
          base64Package = Base64.encode64(file_contents)
        else
          
        end
      end
    
      def destroy_local_metadata(options = { }) 
        api_name  = options[:api_name]
        meta_type = options[:meta_type]
        tmp_dir       = options[:tmp_dir]
           
        FileUtils.rm_r ENV['TM_PROJECT_DIRECTORY'] + "/src/" + META_DIR_MAP[meta_type] + "/#{api_name}" + META_EXT_MAP[meta_type]
        FileUtils.rm_r ENV['TM_PROJECT_DIRECTORY'] + "/src/" + META_DIR_MAP[meta_type] + "/#{api_name}" + META_EXT_MAP[meta_type] + "-meta.xml"
      end
      
      def cleanup_tmp_dir(dir)
        FileUtils.rm_r dir
      end
      
      private
      
        def cleanup_tmp
          FileUtils.rm_rf("#{Dir.tmpdir}/mmzip")
          Dir.mkdir("#{Dir.tmpdir}/mmzip")
          Dir.mkdir("#{Dir.tmpdir}/mmzip/unpackaged")
          Dir.chdir("#{Dir.tmpdir}/mmzip/unpackaged")
        end
      
        def put_files_in_tmp_directories(hash)
          hash.each { |key, value|
            Dir.chdir("#{Dir.tmpdir}/mmzip/unpackaged/#{META_DIR_MAP[key]}")
            value.each do |f|
              FileUtils.copy_file(
                "#{ENV['TM_PROJECT_DIRECTORY']}/src/#{META_DIR_MAP[key]}/#{f}#{META_EXT_MAP[key]}",
                "#{Dir.getwd}/#{f}#{META_EXT_MAP[key]}"
              )
              FileUtils.copy_file(
                "#{ENV['TM_PROJECT_DIRECTORY']}/src/#{META_DIR_MAP[key]}/#{f}#{META_EXT_MAP[key]}-meta.xml",
                "#{Dir.getwd}/#{f}#{META_EXT_MAP[key]}-meta.xml"
              )
            end
          }
        end
      
        def put_tmp_directories(hash)
          hash.each_key { |key|
            Dir.mkdir("#{Dir.tmpdir}/mmzip/unpackaged/#{META_DIR_MAP[key]}")
          }
        end
      
        def zip_tmp_directory
          tmp_dir = Dir.tmpdir
          Dir.chdir("#{tmp_dir}/mmzip")
          Zip::ZipFile.open("deploy.zip", 'w') do |zipfile|
            Dir["#{tmp_dir}/mmzip/**/**"].each do |file|
              zipfile.add(file.sub("#{tmp_dir}/mmzip/",""),file)
            end
          end
          Dir.chdir("#{tmp_dir}/mmzip")
          file_contents = File.read("deploy.zip")
          return Base64.encode64(file_contents)
        end
        
        def put_new_package(where, binding, delete=false)
          Dir.chdir(where)
          file_name = delete ? "destructiveChanges.xml" : "package.xml"
          template = ERB.new File.new("#{ENV['TM_BUNDLE_SUPPORT']}/templates/new_package.html.erb").read, nil, "-"
          erb = template.result(binding)        
          src = File.new(file_name, "w")
          src.puts(erb)
          src.close
        end
        
        def put_package(where, binding, delete=false)
          Dir.chdir(where)
          file_name = delete ? "destructiveChanges.xml" : "package.xml"
          template = ERB.new File.new("#{ENV['TM_BUNDLE_SUPPORT']}/templates/package.html.erb").read, nil, "-"
          erb = template.result(binding)        
          src = File.new(file_name, "w")
          src.puts(erb)
          src.close
        end
              
        def put_empty_package(where)
          Dir.chdir(where)
          template = ERB.new File.new("#{ENV['TM_BUNDLE_SUPPORT']}/templates/empty_package.html.erb").read, nil, "-"
          erb = template.result(binding)       
          src = File.new("package.xml", "w")
          src.puts(erb)
          src.close
        end
            
        def put_src_file(options = { })
          api_name = options[:api_name]
          meta_type = options[:meta_type]
          object_name = options[:object_name]
          file_name = "#{api_name}" + META_EXT_MAP[meta_type]
                
          template = ERB.new File.new("#{ENV['TM_BUNDLE_SUPPORT']}/templates/#{meta_type}.html.erb").read, nil, "%"
          erb = template.result(binding)        
          src = File.new(file_name, "w")
          src.puts(erb)
          src.close       
          return file_name
        end
      
        def put_meta_file(options = { })
          api_name = options[:api_name]
          meta_type = options[:meta_type]
          object_name = options[:object_name]
        
          src_meta_file_name = api_name + META_EXT_MAP[meta_type] + "-meta.xml"
        
          template = ERB.new File.new("#{ENV['TM_BUNDLE_SUPPORT']}/templates/meta.html.erb").read, nil, "-"
          erb = template.result(binding)        
          src = File.new(src_meta_file_name, "w")
          src.puts(erb)
          src.close
        end
         
    end   
  end
end