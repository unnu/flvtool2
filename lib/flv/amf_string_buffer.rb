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

class AMFStringBuffer
  def initialize(str = nil)
    @buffer = str || ''
    @pos = 0
  end
  
  def seek(pos)
    @pos = pos
  end
  
  def read(length)
    raise EOFError if @pos + length > @buffer.length
    rt = @buffer[@pos, length]
    @pos += length
    rt
  end
  
  def readchar
    read(1).unpack('C').first
  end
  
  def write(str)
    if @pos + str.length > @buffer.length
      @buffer << ' ' * (@pos + str.length - @buffer.length)
    end
    @buffer[@pos, str.length] = str
    @pos += str.length
  end

  def close
  end
  
  def to_s
    @buffer
  end

  def length
    @buffer.length
  end

  def eof?
    @pos == length
  end

  def pos
    @pos
  end
  
  def read__AMF_string
    read(read__UI16)
  end
  
  def read__AMF_double
    num = read(8).unpack('G').first.to_f
  end

  def read__AMF_boolean
    read__UI8 == 1
  end
  
  def read__AMF_mixed_array
    size = read__UI32 # is not used
    hash = {}
    while !eof?
      key = read__AMF_string
      break if key.empty? && (type = read__UI8) == 9
      hash[key] = read__AMF_data(type)
    end
    hash
  end

  def read__AMF_object
    object = Object.new
    while !eof?
      key = read__AMF_string
      break if key.empty? && (type = read__UI8) == 9
      object.instance_variable_set( eval(":@#{key}"), read__AMF_data(type) )
    end
    object
  end

  def read__AMF_array
    size = read__UI32
    array = []
    (1..size).step do |pos|  
      break if eof?
      array << read__AMF_data
    end
    array
  end
  
  def read__AMF_date
    utc_time = Time.at((read__AMF_double / 1000).to_i)
    utc_time + (read__SI16 * 60) - Time.now.gmtoff
  end
  
  def read__AMF_data(type = nil)
    type ||= read__UI8
    value = case type.to_i
    when  0
      read__AMF_double
    when  1
      read__AMF_boolean
    when  2
      read__AMF_string
    when  3
      read__AMF_object
    when  8
      read__AMF_mixed_array
    when 10
      read__AMF_array
    when 11
      read__AMF_date
    else
    end
    return value
  end
  
  def write__AMF_string(str)
    write__UI8 2
    write__UI16 str.length
    write str
  end
  
  def write__AMF_double(value)
    write__UI8 0
    write [value].pack('G')
  end

  def write__AMF_boolean(value)
    write__UI8 1
    value = value ? 1 : 0
    write [value].pack('C')
  end
  
  def write__AMF_date(time)
    write__UI8 11
    write [(time.to_f * 1000.0)].pack('G')
    write__SI16( (Time.now.gmtoff / 60).to_i ) 
  end
  
  def write__AMF_data(object)
    if object === true || object === false
      write__AMF_boolean object
    elsif object.kind_of? Numeric
      write__AMF_double object
    elsif object.kind_of? Time
      write__AMF_date object
    elsif object.kind_of? Hash
      write__AMF_mixed_array object
    elsif object.kind_of? String
      write__AMF_string object
    elsif object.kind_of? Array
      write__AMF_array object
    else
      write__AMF_object object
    end
  end
  
  def write__AMF_key(key)
    write__UI16 key.length
    write key
  end
  
  def write__AMF_mixed_array(hash)
    write__UI8 8
    write__UI32 hash.length # length will never be read
    
    hash.each_pair do |key, value|
      write__AMF_key key
      write__AMF_data value
    end
    
    write__UI16 0
    write__UI8 9
  end

  def write__AMF_array(array)
    write__UI8 10
    write__UI32 array.length
    
    array.each do |value|
      write__AMF_data value
    end
  end

  def write__AMF_object(object)
    write__UI8 3
    
    object.instance_variables.each do |variable|
      write__AMF_key variable.gsub('@', '')
      write__AMF_data object.instance_variable_get( variable.intern )
    end
    
    write__UI16 0
    write__UI8 9
  end
  
  # FIXME: This methods are copied from flv_stream.rb. Should get in here per
  # include? or something like this.
  def read__UI8
    readchar
  end
  
  def read__UI16
    (readchar << 8) + readchar
  end
  
  def read__UI24
    (readchar << 16) + (readchar << 8) + readchar
  end
  
  def read__UI32
    (readchar << 24) + (readchar << 16) + (readchar << 8) + readchar
  end
  
  def read__STRING(length)
    read length
  end
    
  def read__SI16
    read(2).reverse.unpack('s').first.to_i
  end
  
  def write__UI8(value)
    write [value].pack('C')
  end
  
  def write__UI16(value)
    write [(value >> 8) & 0xff].pack('c')
    write [value & 0xff].pack('c')
  end

  def write__UI24(value)
    write [value >> 16].pack('c')
    write [(value >> 8) & 0xff].pack('c')
    write [value & 0xff].pack('c')
  end
  
  def write__UI32(value)
    write [value].pack('N')
  end
  
  def write__SI16(value)
    write [(value >> 8) & 0xff].pack('c')
    write [value & 0xff].pack('c')
  end

  def write__STRING(string)
    write string
  end
  alias_method :<<, :write__STRING
  
end

