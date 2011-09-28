module MavensMate
  module Client
    
    class << self
      
      def deploy(ant_build_file)
          message = ''
          success = true
          TextMate::Process.run("ant -buildfile '#{ant_build_file}' deploy", :interactive_input => false) do |str|
            STDOUT << htmlize(str, :no_newline_after_br => true)
            if str.include? "BUILD FAILED"
              success = false 
              message += "[ERROR] "
            end    
            if message.start_with?("[ERROR]")
              message += str
            end
          end
        
          if ! success
            return { :success => false, :message => message }
          end
          
          return { :success => true, :message => "Success" }

        end
    end
  end
end