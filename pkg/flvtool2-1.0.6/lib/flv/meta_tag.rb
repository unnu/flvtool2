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
require 'miyaml'

module FLV
  
  class FLVMetaTag < FLVTag
    
    attr_accessor :meta_data, :event
    
    def after_initialize(new_object)
      @tag_type = META
      unless new_object
        meta_data_stream = AMFStringBuffer.new(@data)
        @event = meta_data_stream.read__AMF_data
        @meta_data = meta_data_stream.read__AMF_data
      else
        @event = 'onMetaData'
        @meta_data = {}
      end
    end

    def name
      "Meta Tag (#{@event})"
    end
    
    def add_meta_data(meta_data)
      return nil if meta_data.nil?
      @metadata.update meta_data
    end
    
    def data
      meta_data_stream = AMFStringBuffer.new('')
      meta_data_stream.write__AMF_string @event
      meta_data_stream.write__AMF_data @meta_data
      meta_data_stream.to_s
    end

    def [](key)
      @meta_data[key]
    end

    def []=(key, value)
      @meta_data[key] = value
    end

    def inspect
      out = super
      out << "event: #{@event}"
      out << "meta_data:\n  #{MiYAML.dump(@meta_data, :indent => 2, :boundaries => false)}"
      out
    end
  end
end
