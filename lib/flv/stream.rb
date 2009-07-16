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

require 'flv/core_extensions'
require 'flv/tag'
require 'flv/audio_tag'
require 'flv/video_tag'
require 'flv/meta_tag'


module FLV
  
  class FLVError < StandardError; end
  class FLVTagError < FLVError; end
  class FLVStreamError < FLVError; end
  
  class FLVStream
    
    attr_accessor :signatur,
                  :version,
                  :type_flags_audio,
                  :type_flags_video,
                  :tags,
                  :stream_log
    
    def initialize(in_stream, out_stream = nil, stream_log = false)

      
      @stream_log = stream_log ? (File.open('stream.log', File::CREAT|File::WRONLY|File::TRUNC) rescue AMFStringBuffer.new) : AMFStringBuffer.new
      @in_stream = in_stream
      @out_stream = out_stream || in_stream

      unless eof?
        begin
          read_header
          read_tags
        rescue Object => e
          log e
          raise e
        ensure
          @stream_log.close
        end
      else
        @version = 1
        @type_flags_audio = false
        @type_flags_video = false
        @extra_data = ''
        @tags = []
      end
    end
    
    
    # general
    def add_tags(tags, stick_on_framerate = true, overwrite = true)
      tags = [tags] unless tags.kind_of? Array
      
      tags.each do |tag|
        
        # FIXME: Does not really work for video or audio tags, because tags are
        #        inserted next to same kind. Normally audio and video tags are 
        #        alternating.
        if stick_on_framerate && !framerate.nil? &&framerate != 0 && tag.timestamp % (1000 / framerate) != 0
          raise FLVTagError, "Could not insert tag. Timestamp #{tag.timestamp} does not fit into framerate."
          next
        end
        
        after_tag = @tags.detect { |_tag| _tag.timestamp >= tag.timestamp }
        
        if after_tag.nil?
          @tags << tag
          next
        end

        if tag.timestamp == after_tag.timestamp && tag.class == after_tag.class
          if tag.kind_of?(FLVMetaTag) && ( ( tag.event != after_tag.event ) || ( tag.event == after_tag.event && !overwrite ) )
            @tags.insert( @tags.index(after_tag), tag )
          else
            @tags[@tags.index(after_tag)] = tag
          end
        else
          @tags.insert( @tags.index(after_tag), tag )
        end
          
        empty_tag_type_cache
      end
      
      @tags
    end

    def cut(options = [])
      @tags.delete_if { |tag| tag.timestamp < ( options[:in_point] || 0 ) || tag.timestamp > ( options[:out_point] || tags.last.timestamp ) }
      if options[:collapse]
        difference = @tags.first.timestamp
        @tags.each { |tag| tag.timestamp -= difference }
      end
      empty_tag_type_cache
    end

    def find_nearest_keyframe_video_tag(position)
      keyframe_video_tags.sort do |tag_a, tag_b|
        (position - tag_a.timestamp).abs <=> (position - tag_b.timestamp).abs
      end.first
    end
    
    def add_meta_tag(meta_data = {})
      meta_tag = FLVMetaTag.new
      meta_tag.event = 'onMetaData'
      
      meta_tag['framerate'] = framerate
      meta_tag['duration'] = duration
      meta_tag['lasttimestamp'] = lasttimestamp
      meta_tag['videosize'] = videosize
      meta_tag['audiosize'] = audiosize
      meta_tag['datasize'] = 0 # calculate after tag was added
      meta_tag['filesize'] = 0 # calculate after tag was added
      meta_tag['width'] = (width == 0 && on_meta_data_tag) ? on_meta_data_tag.meta_data['width'] : width
      meta_tag['height'] = (height == 0 && on_meta_data_tag) ? on_meta_data_tag.meta_data['height'] : height
      meta_tag['videodatarate'] = videodatarate
      meta_tag['audiodatarate'] = audiodatarate
      meta_tag['lastkeyframetimestamp'] = lastkeyframetimestamp
      meta_tag['audiocodecid'] = audiocodecid
      meta_tag['videocodecid'] = videocodecid
      meta_tag['audiodelay'] = audiodelay
      meta_tag['canSeekToEnd'] = canSeekToEnd
      meta_tag['stereo'] = stereo
      meta_tag['audiosamplerate'] = audiosamplerate
      meta_tag['audiosamplesize'] = audiosamplesize
      meta_tag['cuePoints'] = cue_points
      meta_tag['keyframes'] = keyframes
      meta_tag['hasVideo'] = has_video?
      meta_tag['hasAudio'] = has_audio?
      meta_tag['hasMetadata'] = true
      meta_tag['hasCuePoints'] = has_cue_points?
      meta_tag['hasKeyframes'] = has_keyframes?

      meta_tag.meta_data.merge!(meta_data)
      
      add_tags(meta_tag)

      # recalculate values those need meta tag data size or presence
      meta_tag['keyframes'] = keyframes
      meta_tag['datasize'] = datasize
      meta_tag['filesize'] = filesize
      meta_tag['hasMetadata'] = has_meta_data?
    end
    
    def write

      begin
        @out_stream.seek( 0 )
      rescue Object => e
      end
      
      write_header
      write_tags

      begin
        @out_stream.truncate( @out_stream.pos )
      rescue Object => e
      end
    end
    
    def close
      @in_stream.close
      @out_stream.close
    end

    
    # views on tags

    def empty_tag_type_cache
      @video_tags_cache = nil
      @keyframe_video_tags_cache = nil
      @audio_tags_cache = nil
      @meta_tags_cache = nil
      @on_cue_point_tags_cache = nil
    end
    
    def video_tags
      @video_tags_cache ||= @tags.find_all { |tag| tag.kind_of? FLVVideoTag }
    end
    
    def keyframe_video_tags
      @keyframe_video_tags_cache ||= @tags.find_all do |tag|
        tag.kind_of?(FLVVideoTag) && tag.frame_type == FLVVideoTag::KEYFRAME
      end
    end
    
    def audio_tags
      @audio_tags_cache ||= @tags.find_all { |tag| tag.kind_of? FLVAudioTag }
    end
    
    def meta_tags
      @meta_tags_cache ||= @tags.find_all { |tag| tag.kind_of? FLVMetaTag }
    end
    
    def on_meta_data_tag
      @tags.find { |tag| tag.kind_of?(FLVMetaTag) && tag.event == 'onMetaData' } # FIXME: Cannot be cached
    end

    def on_cue_point_tags
      @on_cue_point_tags_cache ||= @tags.find_all { |tag| tag.kind_of?(FLVMetaTag) && tag.event == 'onCuePoint' } # FIXME: Cannot be cached
    end

    def has_video?
      video_tags.size > 0
    end

    def has_audio?
      audio_tags.size > 0
    end

    def has_meta_data?
      !on_meta_data_tag.nil?
    end
    
    def has_cue_points?
      on_cue_point_tags.size > 0
    end

    def has_keyframes?
      keyframe_video_tags.size > 0
    end
    
    # meta data

    # FIXME: Could be less complicate and run faster
    def frame_sequence
      return nil unless has_video?
      raise(FLVStreamError, 'File has to contain at least 2 video tags to calculate frame sequence') if video_tags.length < 2

      @frame_sequence ||=
      begin
        sequences = video_tags.collect do |tag| # find all sequences
          video_tags[video_tags.index(tag) + 1].timestamp - tag.timestamp unless tag == video_tags.last
        end.compact
        
        uniq_sequences = (sequences.uniq - [0]).sort # remove 0 and try smallest intervall first 
        
        sequence_appearances = uniq_sequences.collect { |sequence| sequences.find_all { |_sequence| sequence == _sequence }.size } # count apperance of each sequence
        
        uniq_sequences[ sequence_appearances.index( sequence_appearances.max ) ] # return the sequence that appears most
      end
    end
    
    def framerate
      return nil unless has_video?
      frame_sequence == 0 ? 0 : 1000 / frame_sequence
    end
    
    def duration
      lasttimestamp
    end
    
    def lasttimestamp
      last_tag = if has_video?
          video_tags.last
        elsif has_audio?
          audio_tags.last
        else
          tags.last
        end
      last_tag.timestamp.nil? ? 0 : last_tag.timestamp / 1000.0
    end
    
    def lastkeyframetimestamp
      return nil unless has_video?
      (keyframe_video_tags.last.nil? || keyframe_video_tags.last.timestamp.nil?) ? 0 : keyframe_video_tags.last.timestamp / 1000.0
    end
    
    def videosize
      video_tags.inject(0) { |size, tag| size += tag.size }
    end
    
    def audiosize
      audio_tags.inject(0) { |size, tag| size += tag.size }
    end
    
    def datasize
      videosize + audiosize + (meta_tags.inject(0) { |size, tag| size += tag.size})
    end
    
    def filesize
      # header + data + backpointers 
      @data_offset + datasize + ((@tags.length + 1) * 4)
    end
    
    def width
      return nil unless has_video?
      video_tags.first.width || 0
    end
    
    def height
      return nil unless has_video?
      video_tags.first.height || 0
    end
    
    def videodatarate
      data_size = video_tags.inject(0) do |size, tag|
        size += tag.data_size
      end
      return data_size == 0 ? 0 : data_size / duration * 8 / 1000 # kBits/sec
    end
    
    def audiodatarate
      data_size = audio_tags.inject(0) do |size, tag|
        size += tag.data_size
      end
      return data_size == 0 ? 0 : data_size / duration * 8 / 1000 # kBits/sec
    end

    def stereo
      audio_tags.first && audio_tags.first.sound_type == FLVAudioTag::STEREO
    end

    def audiosamplerate
      audio_tags.first && audio_tags.first.sound_rate
    end

    def audiosamplesize
      audio_tags.first && audio_tags.first.sound_sample_size
    end
    
    def audiocodecid
      audio_tags.first && audio_tags.first.sound_format
    end

    def videocodecid
      return nil unless has_video?
      video_tags.first.codec_id
    end

    def audiodelay
      return 0 unless has_video?
      video_tags.first.timestamp.nil? ? 0 : video_tags.first.timestamp / 1000.0
    end

    def canSeekToEnd
      return true unless has_video?
      video_tags.last.frame_type == FLVVideoTag::KEYFRAME
    end

    def keyframes
      object = Object.new
      
      calculate_tag_byte_offsets
      
      object.instance_variable_set( :@times, keyframe_video_tags.collect { |video_tag| video_tag.timestamp / 1000.0 } )
      object.instance_variable_set( :@filepositions, keyframe_video_tags.collect { |video_tag| video_tag.byte_offset } )
      
      return object
    end

    def cue_points
      on_cue_point_tags.collect { |tag| tag.meta_data }
    end
    
    def <<(tags)
      add_tags tags, true
    end
    
    private
      def calculate_tag_byte_offsets
        @tags.inject(@data_offset + 4) { |offset, tag| tag.byte_offset = offset; offset += 4 + tag.size }
      end
    
      def read_header
        begin
          @signature = @in_stream.read__STRING(3)
          log "File signature: #{@signature}"
          raise(FLVStreamError, 'IO is not a FLV stream. Wrong signature.') if @signature != 'FLV'
          
          @version = @in_stream.read__UI8
          log "File version: #{@version}"
          
          type_flags = @in_stream.read__UI8
          @type_flags_audio = (type_flags & 4) == 1
          log "File has audio: #{@type_flags_audio}"
          
          @type_flags_video = (type_flags & 1) == 1
          log "File has video: #{@type_flags_video}"
          
          @data_offset = @in_stream.read__UI32
          log "File header size: #{@data_offset}"
          
          @extra_data = @in_stream.read__STRING @data_offset - 9
          log "File header extra data: #{@extra_data}"
          
        rescue IOError => e
          raise IOError, "IO Error while reading FLV header. #{e.message}", e.backtrace
        end
      end
      
      def write_header
        begin
          @out_stream.write__STRING 'FLV'
          @out_stream.write__UI8 1
          type_flags = 0
          type_flags += 4 if has_audio?
          type_flags += 1 if has_video?
          @out_stream.write__UI8 type_flags
          @out_stream.write__UI32 9 + @extra_data.length
          @out_stream.write__STRING @extra_data
        rescue IOError => e
          raise IOError, "IO Error while writing FLV header. #{e.message}", e.backtrace
        end
      end
      
      def read_tags
        @tags ||= []
        
        while true
          break if eof?
          previous_tag_length = @in_stream.read__UI32
          log "Previous tag length: #{previous_tag_length}"
          
          break if eof?
          log "Tag number: #{@tags.size + 1}"
          tag_type = @in_stream.read__UI8
          log "Tag type: #{FLVTag.type2name(tag_type)}"

          break if eof?
          case tag_type
          when FLVTag::AUDIO
            @tags << FLVAudioTag.new(@in_stream)
          when FLVTag::VIDEO
            @tags << FLVVideoTag.new(@in_stream)
          when FLVTag::META
            @tags << FLVMetaTag.new(@in_stream)
          else
            @tags << FLVTag.new(@in_stream)
          end

        end
        
        if $VERBOSE
          total_known_tags =
            audio_tags.size + video_tags.size + meta_tags.size
          out =  "Read tags: #{audio_tags.size} audio, #{video_tags.size} video,"
          out << " #{meta_tags.size} meta,"
          out << " #{@tags.size - total_known_tags} unknown,"
          out << " #{@tags.size} total\n"
          puts out
        end
      end
      
      def write_tags
        
        @out_stream.write__UI32 0

        count = 0
        @tags.each do |tag|
          tag.serialize @out_stream
          @out_stream.write__UI32 tag.size
          count += 1
          puts "[#{count}]#{tag.inspect}\n" if $VERBOSE
        end

        puts "Wrote tags: #{count} total" if $VERBOSE
      end

      def log(msg)
        @stream_log << msg.to_s + "\n"
      end

      def eof?
        @in_stream.eof?
      end
  end
end
