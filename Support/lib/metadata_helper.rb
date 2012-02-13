module MetadataHelper
  
  MM_API_VERSION = ENV['MM_API_VERSION'] || "23.0" 
  META_DICTIONARY = eval(File.read("#{ENV['TM_BUNDLE_SUPPORT']}/conf/metadata_dictionary"))
  CHILD_META_DICTIONARY = eval(File.read("#{ENV['TM_BUNDLE_SUPPORT']}/conf/metadata_children_dictionary"))
  
  META_LABEL_MAP = { 
    "ApexClass" => "Apex Class", 
    "ApexComponent" => "Visualforce Component", 
    "ApexPage" => "Visualforce Page", 
    "ApexTrigger" => "Apex Trigger", 
    "StaticResource" => "Static Resource" 
  }
  
  META_DIR_MAP = { 
    "ApexClass" => "classes", 
    "ApexComponent" => "components", 
    "ApexPage" => "pages", 
    "ApexTrigger" => "triggers", 
    "StaticResource" => "staticresources" 
  }
  
  META_EXT_MAP = { 
    "ApexClass" => ".cls", 
    "ApexComponent" => ".component", 
    "ApexPage" => ".page", 
    "ApexTrigger" => ".trigger", 
    "StaticResource" => ".resource" 
  }
  
  EXT_META_MAP = { 
    ".cls" => "ApexClass", 
    ".component" => "ApexComponent", 
    ".page" => "ApexPage", 
    ".trigger" => "ApexTrigger", 
    ".resource" => "StaticResource" 
  }
   
end
