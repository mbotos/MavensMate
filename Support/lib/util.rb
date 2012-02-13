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
        
    end
  end
end