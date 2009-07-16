# Copyright (c) 2005 Norman Timmler (inlet media e.K., Hamburg, Germany)
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'flvtool2/version'
require 'flvtool2/base'

module FLVTool2
  
  SHELL_COMMAND_NAME = (RUBY_PLATFORM =~ /win32/) ? 'flvtool2.exe' : 'flvtool2'
  SWITCHES = %w{ s v r p x c i o k t n l a }
  COMMANDS = %w{ U C P D A V }
  
  def self.parse_arguments
    options = {}
    options[:commands] = []
    options[:metadatacreator] = "inlet media FLVTool2 v#{PROGRAMM_VERSION.join('.')} - http://www.inlet-media.de/flvtool2"
    options[:metadata] = {}
    options[:in_path] = nil
    options[:in_pipe] = false
    options[:out_path] = nil
    options[:out_pipe] = false
    options[:simulate] = false
    options[:verbose] = false
    options[:recursive] = false
    options[:preserve] = false
    options[:xml] = false
    options[:compatibility_mode] = false
    options[:in_point] = nil
    options[:out_point] = nil
    options[:keyframe_mode] = false
    options[:tag_file] = nil
    options[:tag_number] = nil
    options[:stream_log] = false
    options[:collapse] = false

    while (arg = ARGV.shift)
      case arg
      when /^-([a-zA-Z0-9]+?):(.+)$/
        options[:metadata][$1] = $2
      when /^-([a-zA-Z0-9]+?)#([0-9]+)$/
        options[:metadata][$1] = $2.to_f
      when /^-([a-zA-Z0-9]+?)@(\d{4,})-(\d{2,})-(\d{2,}) (\d{2,}):(\d{2,}):(\d{2,})$/
        options[:metadata][$1] = Time.local($2, $3, $4, $5, $6, $7)
      when /^-(.+)$/
        $1.split(//).flatten.each do |switch|  
          case switch
          when 's'
            options[:simulate] = true
          when 'v'
            options[:verbose] = true
          when 'r'
            options[:recursive] = true
          when 'p'
            options[:preserve] = true
          when 'x'
            options[:xml] = true
          when 'c'
            options[:compatibility_mode] = true
          when 'i'
            options[:in_point] = ARGV.shift.to_i
          when 'o'
            options[:out_point] = ARGV.shift.to_i
          when 'k'
            options[:keyframe_mode] = true
          when 't'
            options[:tag_file] = ARGV.shift
          when 'n'
            options[:tag_number] = ARGV.shift.to_i
          when 'l'
            options[:stream_log] = true
          when 'a'
            options[:collapse] = true
          when 'U'
            options[:commands] << :update
          when 'P'
            options[:commands] << :print
          when 'C'
            options[:commands] << :cut
          when 'D'
            options[:commands] << :debug
          when 'A'
            options[:commands] << :add
          when 'H'
            options[:commands] << :help
          when 'V'
            options[:commands] << :version
          end
        end
      when /^([^-].*)$/
        if options[:in_path].nil? 
          options[:in_path] = $1
          if options[:in_path].downcase =~ /stdin|pipe/
            options[:in_pipe] = true
            options[:in_path] = 'pipe'
          else
            options[:in_path] = File.expand_path( options[:in_path] )
          end
        else
          options[:out_path] = $1
          if options[:out_path].downcase =~ /stdout|pipe/
            options[:out_pipe] = true
            options[:out_path] = 'pipe'
          else
            options[:out_path] = File.expand_path( options[:out_path] )
          end
        end
      end
    end
    
    return options
  end
  
  def self.validate_options( options )
    if options[:commands].empty?
      show_usage
      exit 0
    end
    
    options[:commands].each do |command|  
      case command
      when :print
        if options[:out_pipe]
          throw_error "Could not use print command in conjunction with output piping or redirection"
          exit 1
        end
      when :debug
        if options[:out_pipe]
          throw_error "Could not use debug command in conjunction with output piping or redirection"
          exit 1
        end
      when :help
        show_usage
        exit 0
      when :version
        show_version
        exit 0
      end
    end
    options
  end
  
  def self.execute!(options)
    if options[:commands].include? :help
      show_usage
    else
      FLVTool2::Base::execute!( options )
    end
  end

  def self.show_version
    puts "FLVTool2 #{version}"
  end
  
  def self.show_usage
    self.show_version
    puts "Copyright (c) 2005-2007 Norman Timmler (inlet media e.K., Hamburg, Germany)\n"
    puts "Get the latest version from http://www.inlet-media.de/flvtool2\n"
    puts "This program is published under the BSD license.\n"
    puts "\n"
    puts "Usage: #{SHELL_COMMAND_NAME} [-#{COMMANDS.sort.join}#{SWITCHES.sort.join}]... [-key:value]... in-path|stdin [out-path|stdout]\n"
    puts "\n"
    puts "If out-path is omitted, in-path will be overwritten.\n"
    puts "In-path can be a single file, or a directory. If in-path is a directory,\n"
    puts "out-path has to be likewise, or can be omitted. Directory recursion\n"
    puts "is controlled by the -r switch. You can use stdin and stdout keywords\n"
    puts "as in- and out-path for piping or redirecting.\n"
    puts "\n"
    puts "Chain commands like that: -UP (updates FLV file than prints out meta data)\n"
    puts "\n"
    puts "Commands:\n"
    puts "  -A            Adds tags from -t tags-file\n"
    puts "  -C            Cuts file using -i inpoint and -o outpoint\n"
    puts "  -D            Debugs file (writes a lot to stdout)\n"
    puts "  -H            Helpscreen will be shown\n"
    puts "  -P            Prints out meta data to stdout\n"
    puts "  -U            Updates FLV with an onMetaTag event\n"
    puts "\n"
    puts "Switches:\n"
    puts "  -a            Collapse space between cutted regions\n"
    puts "  -c            Compatibility mode calculates some onMetaTag values different\n"
    puts "  -key:value    Key-value-pair for onMetaData tag (overwrites generated values)\n"
    puts "  -i timestamp  Inpoint for cut command in miliseconds\n"
    puts "  -k            Keyframe mode slides onCuePoint(navigation) tags added by the\n"
    puts "                add command to nearest keyframe position\n"
    puts "  -l            Logs FLV stream reading to stream.log in current directory\n"
    puts "  -n            Number of tag to debug\n"
    puts "  -o timestamp  Outpoint for cut command in miliseconds\n"
    puts "  -p            Preserve mode only updates FLVs that have not been processed\n"
    puts "                before\n"
    puts "  -r            Recursion for directory processing\n"
    puts "  -s            Simulation mode never writes FLV data to out-path\n"
    puts "  -t path       Tagfile (MetaTags written in XML)\n"
    puts "  -v            Verbose mode\n"
    puts "  -x            XML mode instead of YAML mode\n"
    puts "\n"
    puts "REPORT BUGS at http://projects.inlet-media.de/flvtool2"
    puts "Powered by Riva VX, http://rivavx.com\n"
  end
  
  def self.throw_error(error)
    puts "ERROR: #{error}"
  end
end


FLVTool2::execute!( FLVTool2::validate_options( FLVTool2::parse_arguments ) )
exit 0

