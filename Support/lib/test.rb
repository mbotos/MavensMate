MM_ROOT = File.dirname(__FILE__)
ENV['TM_BUNDLE_SUPPORT'] = MM_ROOT + "/.."

SUPPORT = ENV['TM_SUPPORT_PATH']
BUNDLESUPPORT = ENV['TM_BUNDLE_SUPPORT']
require SUPPORT + '/lib/exit_codes'
require SUPPORT + '/lib/escape'
require SUPPORT + '/lib/textmate'
require SUPPORT + '/lib/ui'
require SUPPORT + '/lib/tm/process'
require SUPPORT + '/lib/web_preview'
require SUPPORT + '/lib/progress'
require 'rexml/document'
require 'fileutils'   
require BUNDLESUPPORT + '/lib/client'
require BUNDLESUPPORT + '/lib/factory'
require BUNDLESUPPORT + '/lib/exceptions'
require BUNDLESUPPORT + '/lib/metadata_helper'

require 'rubygems'

