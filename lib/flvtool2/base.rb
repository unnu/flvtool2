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


require 'flv'
require 'mixml'
require 'miyaml'

module FLVTool2
  
  module Base

    class << self
    
      def execute!(options)
  
        options[:commands].each do |command|
          before_filter = "before_#{command.to_s}".intern
          send(before_filter, options) if respond_to? before_filter
        end
        
        process_files(options) do |stream, in_path, out_path|
          write_stream = false
          options[:commands].each do |command|
            write_stream = true if send( command, options, stream, in_path, out_path )
          end
          stream.write if write_stream && !options[:simulate]
        end
  
        options[:commands].each do |command|
          after_filter = "after_#{command.to_s}".intern
          send(after_filter, options) if respond_to? after_filter
        end
      end
  
  
      def add(options, stream, in_path, out_path)
        tag_structures = MiXML.parse( File.open( options[:tag_file], File::RDONLY ) { |file| file.readlines }.join )
  
        add_tag = Proc.new do |data|  
          
          tag = FLV::FLVMetaTag.new
  
          overwrite = ( data['overwrite'] && data['overwrite'].downcase ) == 'true' || false
          data.delete( 'overwrite' )
          
          tag.event = data['event'] || 'event'
          data.delete( 'event' )
          
          tag.timestamp = ( data['timestamp'] && data['timestamp'].to_i ) || 0
          tag.timestamp = stream.find_nearest_keyframe_video_tag(tag.timestamp).timestamp if options[:keyframe_mode] && data['type'] == 'navigation'
          data.delete( 'timestamp' )
          data['time'] = tag.timestamp / 1000
          
          tag.meta_data.merge!( data )
  
          stream.add_tags( tag, false, overwrite )
        end
        
        tag_structures['tags'].each do |tag_name, value|
          case tag_name
          when 'metatag'
            if value.class == Array
              value.each { |_value| add_tag.call( _value ) } 
            else
              add_tag.call( value )
            end
          else
          end
        end
        
        return true
      end
  
      
      def debug(options, stream, in_path, out_path)
  
        puts "---\n"
        puts "path: #{in_path}"
      
        unless stream.nil?
          if options[:tag_number]
            puts "  tag_number: #{options[:tag_number]}"
            puts "  " + stream.tags[ options[:tag_number] - 1 ].inspect.join( "\n  " )
          else
            stream.tags.each_with_index do |tag, index|
              puts "##{index + 1} #{tag.info}"
            end
          end
        end
  
        return false
      end
  
      
      def cut(options, stream, in_path, out_path)
  
        in_point = options[:keyframe_mode] ? stream.find_nearest_keyframe_video_tag(options[:in_point] || 0).timestamp : options[:in_point]
        stream.cut( :in_point => in_point, :out_point => options[:out_point], :collapse => options[:collapse] )
  
        return true
      end
  
      
      def update(options, stream, in_path, out_path)
        
        if ( 
              options[:preserve] && 
              ( 
                !stream.on_meta_data_tag ||
                ( stream.on_meta_data_tag && stream.on_meta_data_tag.meta_data['metadatacreator'] != options[:metadatacreator] ) 
              ) 
           ) || !options[:preserve]
          
          add_meta_data_tag( stream, options )
  
          return true
        else
          puts 'Input file is FLV v1.1 yet. No update necessary.' if options[:verbose]
          
          return false
        end
      end
  
      
      def before_print(options)
        puts "<?xml version=\"1.0\"?>\n<fileset>" if options[:xml]
      end
      
      def print(options, stream, in_path, out_path)
        
        if options[:xml]
          puts "  <flv name=\"#{in_path}\">"
          puts MiXML.dump( stream.on_meta_data_tag && stream.on_meta_data_tag.meta_data, 2 )
          puts "  </flv>"
        else
          puts MiYAML.dump( { in_path => ( stream.on_meta_data_tag && stream.on_meta_data_tag.meta_data ) } )
        end
  
        return false
      end
  
      def object_to_hash(object)
        object.instance_variables.inject( {} ) do |hash, variable|
          hash[variable.gsub('@', '')] = object.instance_variable_get( variable.intern )
          hash
        end
      end
      
      def after_print(options)
        puts '</fileset>' if options[:xml]
      end
  
  
      def add_meta_data_tag(stream, options)
        # add onLastSecond tag
        onlastsecond = FLV::FLVMetaTag.new
        onlastsecond.event = 'onLastSecond'
        onlastsecond.timestamp = ((stream.duration - 1) * 1000).to_int
        stream.add_tags(onlastsecond, false) if onlastsecond.timestamp >= 0
  
        stream.add_meta_tag({ 'metadatacreator' => options[:metadatacreator], 'metadatadate' => Time.now }.merge(options[:metadata]))
        unless options[:compatibility_mode]
          stream.on_meta_data_tag.meta_data['duration'] += (stream.frame_sequence || 0) / 1000.0
        end
      end
  
  
  
      
      def process_files(options)
  
        if options[:in_pipe]
  
          unless options[:omit_out] || options[:out_path].nil?
            create_directories_for_path( options[:out_path] )
            out_path = options[:out_path]
          else
            out_path = nil
          end
          
          begin
            stream = open_stream( 'pipe', out_path )
            yield stream, 'pipe', out_path
            begin
              stream.close
            rescue
            end
            
          rescue Exception => e
            show_exception(e, options)
          end
          
        else
        
          if File.directory?( options[:in_path] )
            pattern = options[:recursive] ? "#{File::SEPARATOR}**#{File::SEPARATOR}*.flv" : "#{File::SEPARATOR}*.flv"
            file_names = Dir[options[:in_path] + pattern]
          else
            file_names = [options[:in_path]]
          end
          
          file_names.each do |in_path|
  
            if options[:out_pipe]
              out_path = 'pipe'
            else
              out_path = options[:out_path]
              unless options[:out_path].nil?
                out_path = in_path.gsub( options[:in_path], options[:out_path] )
                create_directories_for_path( out_path )
              end
            end
            
            begin
              stream = open_stream( in_path, out_path, options[:stream_log] )
              yield stream, in_path, out_path
  
              begin
                stream.close
              rescue
              end
              
            rescue Exception => e
              show_exception(e, options)
            end
          end
        end
      end
  
      def open_stream(in_path, out_path = nil, stream_log = false)
        attributes = (RUBY_PLATFORM =~ /win32/) ? File::BINARY : 0
  
        if in_path == 'pipe'
          in_stream = $stdin
        elsif in_path == out_path || out_path.nil?
          in_stream = File.open( in_path, File::RDWR|attributes )
        else
          in_stream = File.open( in_path, File::RDONLY|attributes )
        end
  
        if out_path == 'pipe' || ( in_path == 'pipe' && out_path.nil? )
          out_stream = $stdout
        elsif in_path != out_path && !out_path.nil?
          out_stream = File.open( out_path, File::CREAT|File::WRONLY|attributes )
        else
          out_stream = nil
        end
        
        FLV::FLVStream.new( in_stream, out_stream, stream_log )
      end
      
      def create_directories_for_path(path_to_build)
        parts = path_to_build.split(File::SEPARATOR)
        parts.shift #removes '/' or 'c:\'
        parts.pop # removes filename
        
        parts.inject('') do |path, dir|
          begin
            path += File::SEPARATOR + dir
            Dir.mkdir path
          rescue Object => e
            raise e unless File.directory?(path)
          end
          path
        end
      end
  
      def show_exception(e, options)
        puts "ERROR: #{e.message}\nERROR: #{e.backtrace.join("\nERROR: ")}"
        puts "Skipping file #{options[:in_path]}\n" if options[:verbose]
      end
    end
  end
end
