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


module FLV
  
  class FLVAudioTag < FLVTag

    UNCOMPRESSED = 0
    ADPCM = 1
    MP3 = 2
    NELLYMOSER8KHZMONO = 5
    NELLYMOSER = 6
    
    MONO = 0
    STEREO = 1

    attr_reader :sound_format,
                :sound_rate,
                :sound_sample_size,
                :sound_type
    
    def after_initialize(new_object)
      @tag_type = AUDIO
      read_header
    end

    def name
      'Audio Tag'
    end

    def read_header
      data_stream = AMFStringBuffer.new(@data)
      bit_sequence = data_stream.read__STRING(1).unpack('B8').to_s
      
      @sound_format = bit2uint(bit_sequence[0,4])
      @sound_rate = case bit2uint(bit_sequence[4,2])
      when 0
        5500
      when 1
        11000
      when 2
        22000
      when 3
        44000
      end
      @sound_sample_size = case bit2uint(bit_sequence[6,1])
      when 0
        8
      when 1
        16
      end
      @sound_type = bit2uint(bit_sequence[7,1])

      # Nellymoser 8kHz mono special case
      if @sound_format == NELLYMOSER8KHZMONO
        @sound_rate = 8000
        @sound_type = MONO
      end
    end

    def inspect
      out = super
      out << "sound_format: #{['Uncompressed', 'ADPCM', 'MP3', nil, nil, 'Nellymoser 8KHz mono', 'Nellymoser'][@sound_format]}"
      out << "sound_rate: #{@sound_rate}"
      out << "sound_sample_size: #{@sound_sample_size}"
      out << "sound_type: #{['Mono', 'Stereo'][@sound_type]}"
      out
    end
  end
end
