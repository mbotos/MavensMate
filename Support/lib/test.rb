#!/usr/bin/env ruby -W0
MM_ROOT = File.dirname(__FILE__)
ENV['TM_BUNDLE_SUPPORT'] = MM_ROOT + "/.."
SUPPORT = ENV['TM_SUPPORT_PATH']
BUNDLESUPPORT = ENV['TM_BUNDLE_SUPPORT']
require BUNDLESUPPORT + '/lib/mavensmate'
require SUPPORT + '/lib/exit_codes'
require SUPPORT + '/lib/escape'
require SUPPORT + '/lib/textmate'
require SUPPORT + '/lib/ui'
#require SUPPORT + '/lib/tm/process'
require SUPPORT + '/lib/web_preview'
require SUPPORT + '/lib/progress'
require 'rexml/document'
require 'fileutils'
require BUNDLESUPPORT + '/lib/client'
require BUNDLESUPPORT + '/lib/factory'
require BUNDLESUPPORT + '/lib/exceptions'
require BUNDLESUPPORT + '/lib/metadata_helper'
require BUNDLESUPPORT + '/lib/util'
require ENV['TM_SUPPORT_PATH'] + '/lib/ui'
require ENV['TM_SUPPORT_PATH'] + '/lib/current_word'
#current_word = ENV['TM_CURRENT_WORD']
current_word = Word.current_word(/\.([-a-zA-Z0-9_]+)/,:left)
puts current_word
abort if current_word.nil?
suggestions = []
    
if File.exist?("#{ENV['TM_BUNDLE_SUPPORT']}/lib/apex/#{current_word.downcase!}.yaml")
  apex_methods({:method_type => "static_methods", :object => current_word}).each do |m|
    suggestions.push({ "display" => m })
  end
  selection = TextMate::UI.complete(suggestions, {:case_insensitive => true})
  prints suggestions[selection] if not selection.nil?
else
  current_object = ""
  lines=[]
  File.open(ENV['TM_FILEPATH']) do |file|
     file.each_line do |line| 
         lines.push(line)
     end
  end
  lines = lines[0, ENV['TM_LINE_NUMBER'].to_i - 1]
  lines.reverse!
  lines.each_with_index do |line, index| 
    next if not line.include?(" #{current_word} ")
    line = line.slice(0, line.index(" #{current_word} "))
    line.reverse!
    line = line.slice(0, line.index(/[\[\]\(\)\s]/))
    current_object = line.reverse
    break
  end

  abort if current_object.nil?

  if File.exist?("#{ENV['TM_PROJECT_DIRECTORY']}/config/objects/#{current_object}.object")
    require 'rubygems'
    require 'nokogiri'
    doc = Nokogiri::XML(File.open("#{ENV['TM_PROJECT_DIRECTORY']}/config/objects/#{current_object}.object"))
    doc.remove_namespaces!
    doc.xpath("//fields/fullName").each do |node|
      suggestions.push({ "display" => node.text })
    end
    selection = TextMate::UI.complete(suggestions, {:case_insensitive => true})
    prints suggestions[selection] if not selection.nil?    
  else
    current_object.downcase!
    if File.exist?("#{ENV['TM_BUNDLE_SUPPORT']}/lib/apex/#{current_object}.yaml")
      apex_methods({:method_type => "instance_methods", :object => current_object}).each do |m|
        suggestions.push({ "display" => m })
      end
      selection = TextMate::UI.complete(suggestions, {:case_insensitive => true})
      prints suggestions[selection] if not selection.nil?
    end
  end
end