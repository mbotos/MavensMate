module MavensMate
  module Util
    class << self
      
      include MetadataHelper
      
      def get_random_string(len=8)
        o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten;  
        string = (0..len).map{ o[rand(o.length)]  }.join;
      end
      
      def get_sfdc_endpoint(url)
         endpoint = (url.include? "test") ? "https://test.salesforce.com/services/Soap/u/#{MM_API_VERSION}" : "https://www.salesforce.com/services/Soap/u/#{MM_API_VERSION}"  
      end
      
      def parse_deploy_response(response)
        response = response[:check_deploy_status_response][:result]
        test_failures = []
        test_successes = []
        coverage_warnings = []
        coverage = []
        messages = []
        
        if response[:run_test_result][:failures]
          if ! response[:run_test_result][:failures].kind_of? Array
            test_failures.push(response[:run_test_result][:failures])
          else
            test_failures = response[:run_test_result][:failures]
          end
        end
        
        if response[:run_test_result][:successes]
          if ! response[:run_test_result][:successes].kind_of? Array
            test_successes.push(response[:run_test_result][:successes])
          else
            test_successes = response[:run_test_result][:successes]
          end
        end
        
        if response[:run_test_result][:code_coverage_warnings]
          if ! response[:run_test_result][:code_coverage_warnings].kind_of? Array
            coverage_warnings.push(response[:run_test_result][:code_coverage_warnings])
          else
            coverage_warnings = response[:run_test_result][:code_coverage_warnings]
          end
        end
        
        if response[:run_test_result][:code_coverage]
          if ! response[:run_test_result][:code_coverage].kind_of? Array
            coverage.push(response[:run_test_result][:code_coverage])
          else
            coverage = response[:run_test_result][:code_coverage]
          end
        end
        
        if response[:messages]
          if ! response[:messages].kind_of? Array
            messages.push(response[:messages])
          else
            messages = response[:messages]
          end
        end
        
        return {
          :is_success => response[:success],
          :test_failures => test_failures,
          :test_successes => test_successes,
          :coverage_warnings => coverage_warnings,
          :coverage => coverage,
          :messages => messages
        }
        #end

        #deployment is "successful", but there are compile issues with the metadata
        # if response[:messages].kind_of? Array
        #   response[:messages].each { |message|
        #     if ! message[:success]
        #       return {
        #         :is_success => message[:success],
        #         :line_number => message[:line_number],
        #         :column_number => message[:column_number],
        #         :error_message => message[:problem],
        #         :file_name => message[:file_name]
        #       }
        #     end
        #   }
        #   return {
        #     :is_success => response[:messages][0][:success],
        #     :line_number => response[:messages][0][:line_number],
        #     :column_number => response[:messages][0][:column_number],
        #     :error_message => response[:messages][0][:problem],
        #     :file_name => response[:messages][0][:file_name]
        #   }
        # else
        #   if ! response[:messages][:success]
        #     return {
        #       :is_success => response[:messages][:success],
        #       :line_number => response[:messages][:line_number],
        #       :column_number => response[:messages][:column_number],
        #       :error_message => response[:messages][:problem],
        #       :file_name => response[:messages][:file_name]
        #     }
        #   else
        #     return {
        #       :is_success => true,
        #       :done => true
        #     }
        #   end
        # end

      end
        
    end
  end
end