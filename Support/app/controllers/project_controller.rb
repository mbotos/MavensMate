# encoding: utf-8
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/mavensmate.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/lib/lsof.rb'
require 'json'

class ProjectController < ApplicationController
  
  attr_accessor :client
  
  layout "application", :only => [:index_custom_project, :index]
            
  def index
    render "_project", :locals => { :user_action => params[:user_action] }
  end
  
  def login
    if params[:un].nil? || params[:pw].nil? || params[:server_url].nil?
      TextMate::UI.alert(:warning, "MavensMate", "Please provide Salesforce.com credentials before selecting metadata")
      abort
    end
      
    begin
      TextMate.call_with_progress( :title => "MavensMate", :message => "Validating Salesforce.com Credentials" ) do
        self.client = MavensMate::Client.new({ :username => params[:un], :password => params[:pw], :endpoint => params[:server_url] })
      end
      $stdout.flush
      flush
      if ! self.client.sid.nil? && ! self.client.metadata_server_url.nil?
        puts "<input type='hidden' value='#{self.client.sid}' id='sid'/>"
        puts "<input type='hidden' value='#{self.client.metadata_server_url}' id='murl'/>"
      end
    rescue Exception => e
      TextMate::UI.alert(:warning, "MavensMate", e.message)
    end
  end
  
  def start_server
    exit if fork            # Parent exits, child continues.
    Process.setsid          # Become session leader.
    exit if fork            # Zap session leader.
    
    require 'socket'
    require 'uri'
    pid = fork do
      webserver = TCPServer.new('127.0.0.1', 7125)
      while (session = webserver.accept)
         session.print "HTTP/1.1 200/OK\r\nContent-type:application/json\r\n\r\n"
         #session.print "Request: #{session.gets.inspect}"
         request = session.gets
         tr = request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '')
         params = tr[tr.index("?")+1,tr.length-1]
         #session.print "PARAMS: #{params.inspect}\n"
         ps = params.split("&")
         sid = ""
         murl = ""
         meta_type = ""
         ps.each { |param|
           pair = param.split("=")
           if pair[0] == "sid"
             sid = pair[1]
           elsif pair[0] == "murl"
             murl = pair[1]
           elsif pair[0] == "key"
             meta_type = pair[1]
           end
         }
         cleanmurl = URI.unescape(murl)
         begin
         #session.print "sid: #{sid.inspect}\n"
         #session.print "cleanmurl: #{cleanmurl.inspect}\n"
         #session.print "meta_type: #{meta_type.inspect}\n"
         client = MavensMate::Client.new({ :sid => sid, :metadata_server_url => cleanmurl })
         meta_list = client.list(meta_type)
         #session.print "RESPONSE IS: " + meta_list.inspect
         session.puts meta_list
         rescue Exception => e
           session.print e.message + "\n" + e.backtrace.join("\n")
           session.close
         end
         # begin
         #    session.print "REQUEST IS: " + requested_meta_type
         # rescue Errno::ENOENT
         #    session.print "ERROR"
         # end
         session.close
      end
    end   
    Process.detach(pid)
    puts "<input type='hidden' value='#{pid}' id='pid'/>"
  end
  
  def index_custom_project   
    kill_server
    my_json = File.read("#{ENV['TM_BUNDLE_SUPPORT']}/resource/metadata_describe.json")
    render "_project_custom", :locals => { :user_action => params[:user_action], :my_json => my_json }
  end
  
  def new_custom_project  
    begin
      tree = eval((params[:tree]))
      params[:selected_types] = tree
      result = MavensMate.new_project(params)
      kill_server unless ! result[:is_success]
      render "_project_result", :locals => { :message => result[:error_message], :success => result[:is_success] }
    rescue Exception => e
      #TextMate::UI.alert(:warning, "MavensMate", e.message)
    end
  end
  
  def kill_server
    if Lsof.running?(7125)
      Lsof.kill(7125)
    end
  end
  
  def checkout
    result = MavensMate.checkout_project(params)
    render "_project_result", :locals => { :message => result[:error_message], :success => result[:is_success] }
  end
    
  def new_project  
    #{}%x{kill #{self.pid}} unless self.pid.nil?
    result = MavensMate.new_project(params)
    render "_project_result", :locals => { :message => result[:error_message], :success => result[:is_success] }
  end
  
end