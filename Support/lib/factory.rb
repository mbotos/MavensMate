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
      
      def put_object_metadata(project_name, object_zip)
        project_folder = ENV['FM_PROJECT_FOLDER']
        Dir.chdir(project_folder+"/"+project_name+"/config")
        File.open('metadata.zip', 'wb') {|f| f.write(Base64.decode64(object_zip))}
        Zip::ZipFile.open('metadata.zip') { |zip_file|
            zip_file.each { |f|
              f_path=File.join(project_folder+"/"+project_name+"/config", f.name)
              FileUtils.mkdir_p(File.dirname(f_path))
              zip_file.extract(f, f_path) unless File.exist?(f_path)
            }
          }
        FileUtils.rm_r project_folder+"/"+project_name+"/config/metadata.zip"
        FileUtils.mv project_folder+"/"+project_name+"/config/unpackaged/objects", project_folder+"/"+project_name+"/config"
        FileUtils.rm_r project_folder+"/"+project_name+"/config/unpackaged"
      end
      
      def finish_clean(project_name, project_zip)
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
        
        Dir.foreach("#{project_folder}/#{project_name}/unpackaged") do |meta_folder| #iterate the retrieve data
          next if meta_folder.include? "." #ignore hidden items or package.xml
          
          #create the metadata folder if it's new to the project
          FileUtils.mkdir "#{project_folder}/#{project_name}/src/#{meta_folder}" unless File.directory? "#{project_folder}/#{project_name}/src/#{meta_folder}"
          
          #iterate each metadata folder
          Dir.foreach("#{project_folder}/#{project_name}/unpackaged/#{meta_folder}") do |meta_file|
            next if meta_file == '.' || meta_file == '..'            
            FileUtils.mv "#{project_folder}/#{project_name}/unpackaged/#{meta_folder}/#{meta_file}", "#{project_folder}/#{project_name}/src/#{meta_folder}/#{meta_file}"
          end
        end
        
        Dir.foreach("#{project_folder}/#{project_name}/src") do |meta_folder| #iterate the fresh project folder
          next if meta_folder.include? "." #ignore hidden items or package.xml
          FileUtils.rm_rf "#{project_folder}/#{project_name}/src/#{meta_folder}" if Dir["#{project_folder}/#{project_name}/src/#{meta_folder}/*"].empty?
        end
        
        FileUtils.rm_rf "#{project_folder}/#{project_name}/unpackaged"
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
         meta_type_no_ext = meta_type_ext.gsub(".","")
         mt = get_meta_type_by_suffix(meta_type_no_ext)
         copy_to_dir = "#{ENV['TM_PROJECT_DIRECTORY']}/src/#{mt[:directory_name]}" #=> "/Users/username/Projects/myproject/src/classes"
         TextMate::Process.run("cp -r '#{Dir.getwd}/#{mt[:directory_name]}/' '#{copy_to_dir}'", :interactive_input => false) do |str|
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
      
      def put_empty_metadata
        cleanup_tmp        
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
        api_name        = options[:api_name]
        meta_type       = options[:meta_type]
        object_name     = options[:object_name]        
        dir             = options[:dir]
        apex_class_type = options[:apex_class_type]
        
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

        file_name = put_src_file(:api_name => api_name, :meta_type => meta_type, :object_name => object_name, :apex_class_type => apex_class_type)
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
      
      def get_meta_type_by_suffix(suffix)
        return META_DICTIONARY.detect {|f| f[:suffix] == suffix }
      end
      
      def get_meta_type_by_dir(dir)
        return META_DICTIONARY.detect {|f| f[:directory_name] == dir }
      end
      
      def get_meta_type_by_name(name)
        return META_DICTIONARY.detect {|f| f[:xml_name] == name }
      end
      
      def get_child_meta_type_by_name(name)
        return CHILD_META_DICTIONARY.detect {|f| f[:xml_name] == name }
      end
      
      def put_package(where, binding, delete=false)
        Dir.mkdir(where) unless File.exists?(where)
        Dir.chdir(where)
        #File.delete("#{ENV['TM_PROJECT_DIRECTORY']}/src/package.xml")
        file_name = delete ? "destructiveChanges.xml" : "package.xml"
        template = ERB.new File.new("#{ENV['TM_BUNDLE_SUPPORT']}/templates/package.html.erb").read, nil, "-"
        erb = template.result(binding)        
        src = File.new(file_name, "w")
        src.puts(erb)
        src.close
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
            mt = get_meta_type_by_name(key)
            Dir.chdir("#{Dir.tmpdir}/mmzip/unpackaged/#{mt[:directory_name]}")
            value.each do |f|
              FileUtils.copy_file(
                "#{ENV['TM_PROJECT_DIRECTORY']}/src/#{mt[:directory_name]}/#{f}.#{mt[:suffix]}",
                "#{Dir.getwd}/#{f}.#{mt[:suffix]}"
              )
              if mt[:meta_file]
              FileUtils.copy_file(
                "#{ENV['TM_PROJECT_DIRECTORY']}/src/#{mt[:directory_name]}/#{f}.#{mt[:suffix]}-meta.xml",
                "#{Dir.getwd}/#{f}.#{mt[:suffix]}-meta.xml"
              )
              end
            end
          }
        end
      
        def put_tmp_directories(hash)
          hash.each { |key, value|
            mt = get_meta_type_by_name(key)
            Dir.mkdir("#{Dir.tmpdir}/mmzip/unpackaged/#{mt[:directory_name]}")
            if mt[:in_folder]
              value.each do |v|
                arr = v.split("/")
                if arr.length && arr.length == 2
                  Dir.mkdir("#{Dir.tmpdir}/mmzip/unpackaged/#{mt[:directory_name]}/#{arr[0]}") unless File.exists?("#{Dir.tmpdir}/mmzip/unpackaged/#{mt[:directory_name]}/#{arr[0]}")
                end
              end
            end
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
          apex_class_type = options[:apex_class_type]
          file_name = "#{api_name}" + META_EXT_MAP[meta_type]
          template = nil
          if meta_type == "ApexClass" && ! apex_class_type.nil?
            template_name = ""
            if apex_class_type == "test"
              template_name = "UnitTestApexClass"
            elsif apex_class_type == "batch"
              template_name = "BatchApexClass"
            elsif apex_class_type == "schedulable"
              template_name = "SchedulableApexClass"
            elsif apex_class_type == "email"
              template_name = "EmailServiceApexClass"
            elsif apex_class_type == "url"
              template_name = "UrlRewriterApexClass"
            else
              template_name = "ApexClass"
            end
            template = ERB.new File.new("#{ENV['TM_BUNDLE_SUPPORT']}/templates/#{template_name}.html.erb").read, nil, "%"            
          else
            template = ERB.new File.new("#{ENV['TM_BUNDLE_SUPPORT']}/templates/#{meta_type}.html.erb").read, nil, "%"            
          end               
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