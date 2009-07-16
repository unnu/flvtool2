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

require 'flv/amf_string_buffer'

module FLV
  
  class FLVVideoTag < FLVTag
    
    H263VIDEOPACKET = 2
    SCREENVIDEOPACKET = 3
    ON2VP6 = 4

    KEYFRAME = 1
    INTERFRAME = 2
    DISPOSABLEINTERFRAME = 3

    attr_reader :frame_type,
                :codec_id,
                :width,
                :height
    
    def after_initialize(new_object)
      @tag_type = VIDEO
      read_header
    end

    def name
      case frame_type
      when KEYFRAME
        'Video Tag (Keyframe)'
      when INTERFRAME
        'Video Tag (Interframe)'
      when DISPOSABLEINTERFRAME
        'Video Tag (disposable Interframe)'
      else
        'Video Tag'
      end
    end

    def keyframe?
      frame_type == KEYFRAME
    end

    def interframe?
      frame_type == INTERFRAME || frame_type == DISPOSABLEINTERFRAME
    end
    
    def read_header
      data_stream = AMFStringBuffer.new(@data)

      # the sequence is swaped in the swf-file-format description
      # frame_type <-> codec_id (description: 1. codec_id, 2. frame_type)
      codec_id_and_frame_type = data_stream.read__UI8
      @frame_type = codec_id_and_frame_type >> 4
      @codec_id = codec_id_and_frame_type & 0xf

      bit_sequence = data_stream.read(9).unpack('B72').to_s
      
      if @codec_id == H263VIDEOPACKET
        @width, @height = case bit2uint bit_sequence[30,3]
        when 0
          [bit2uint(bit_sequence[33,8]), bit2uint(bit_sequence[41,8])]
        when 1
          [bit2uint(bit_sequence[33,16]), bit2uint(bit_sequence[49,16])]
        when 2
          [352, 288]
        when 3
          [176, 144]
        when 4
          [128, 96]
        when 5
          [320, 240]
        when 6
          [160, 120]
        end
      elsif @codec_id == SCREENVIDEOPACKET
        @width, @height = bit2uint(bit_sequence[4,12]), bit2uint(bit_sequence[16,12])
      end
    end

    def inspect
      out = super
      out << "frame_type: #{%w{ Keyframe Interframe DisposableInterframe }[@frame_type]}"
      out << "codec_id: #{@codec_id}"
      out << "width: #{@width}"
      out << "height: #{@height}"
      out << "data_size: #{data_size}"
      out
    end
  end
end
