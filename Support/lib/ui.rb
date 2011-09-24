require ENV['TM_SUPPORT_PATH'] + '/lib/escape'
require ENV['TM_SUPPORT_PATH'] + '/lib/osx/plist'

SUPPORTPRE = ENV['TM_SUPPORT_PATH']

require SUPPORTPRE + '/lib/exit_codes'
require SUPPORTPRE + '/lib/escape'
require SUPPORTPRE + '/lib/textmate'
require SUPPORTPRE + '/lib/ui'
require SUPPORTPRE + '/lib/tm/process'
require SUPPORTPRE + '/lib/web_preview'

TM_DIALOG = e_sh ENV['DIALOG'] unless defined?(TM_DIALOG)

module MavensMate

  module UI
    
    class << self
      # launch new project dialog
      def new_project_dialog
        params = Hash.new
        params["sfdc_un"] = ""
        params["sfdc_pw"] = ""
        params["sfdc_server_url"] = "https://www.salesforce.com"
        params["svn_un"] = ""
        params["svn_pw"] = ""
        params["svn_url"] = ""
        params["button_create"] = ""
        params["button_cancel"] = ""
        params["title"] = ""        
        params["project_name"] = ""    
        return_plist = %x{#{TM_DIALOG} -cmp #{e_sh params.to_plist} #{e_sh("../nibs/NewProject.nib")}}
        return_hash = OSX::PropertyList::load(return_plist)
        return_value = return_hash['result']
        return_value = return_value['returnArgument'] if not return_value.nil?
        
        if return_value == nil then
          block_given? ? raise(SystemExit) : nil
        else
          block_given? ? yield(return_value) : return_value
        end
        
        return return_hash        
      end
      
      # launch new apex class dialog
      def new_apex_class_dialog
        return TextMate::UI.request_string(
          :title => "ForceMate | New Apex Class",
          :prompt => "Class Name:")
      end
      
      # launch new apex class dialog
      def new_vf_page_dialog
        return TextMate::UI.request_string(
          :title => "ForceMate | New Visualforce Page",
          :prompt => "Page Name:")
      end
      
      # launch new apex class dialog
      def new_apex_trigger_dialog
        return TextMate::UI.request_string(
          :title => "ForceMate | New Apex Trigger",
          :prompt => "Trigger Name:")
      end
    
    end  
  end
end