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
require 'flv/stream'


module FLV
  
  class FLVTag
    
    AUDIO = 8
    VIDEO = 9
    META = 18
    UNDEFINED = 0
    
    attr_accessor :tag_type,
                  :timestamp,
                  :byte_offset
    
    def initialize(stream = nil)
      @tag_type = UNDEFINED
      @byte_offset = nil
      
      unless stream.nil?
        data_size = stream.read__UI24
        @timestamp = stream.read__UI24
        stream.read__UI32
        @data = stream.read(data_size)
      else
        @timestamp = 0
        @data = ''
      end
      after_initialize(stream.nil?) if respond_to? :after_initialize
    end
    
    def size
      # header(11) + body(data_size)
      11 + data_size
    end

    def name
      'Unknown Tag'
    end
    
    def data
      @data
    end
    
    def data_size
      data.length
    end
    
    def serialize(stream)
      stream.write__UI8 tag_type
      stream.write__UI24 data_size
      stream.write__UI24 timestamp
      stream.write__UI32 0
      stream.write__STRING data
    end

    def info
      "#{name}: timestamp #{timestamp}, size #{size}, data size #{data_size}"
    end

    def inspect
      out = ["tag: #{self.class}"]
      out << "timestamp: #{@timestamp}"
      out << "size: #{size}"
      out << "data_size: #{data_size}"
      out
    end

    def self.type2name(type)
      case type
      when AUDIO
        'audio'
      when VIDEO
        'video'
      when META
        'meta'
      when UNDEFINED
        'undefined'
      else
        "unknown(#{type})"
      end
    end
    
    private
      def bit2uint(sequence)
        int = 0
        sequence.split(//).each_with_index do |character, i|
          int += 2 ** (sequence.length - i - 1) if character == '1'
        end
        int
      end
  end
end
