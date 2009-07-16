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


class Time
  alias :to_str :to_s
  DAY_NAME = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ]
  MONTH_NAME = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ]
  def to_s
    sprintf('%s %s %d %02d:%02d:%02d GMT',
      DAY_NAME[wday],
      MONTH_NAME[mon-1], day,
      hour, min, sec) +
      (
        off = Time.now.gmtoff
        sign = off < 0 ? '-' : '+'
        sprintf('%s%02d%02d', sign, *(off.abs / 60).divmod(60))
      ) +
      (
        sprintf(' %d', year)
      )
  end
  def to_iso
    offset = Time.now.gmtoff
    strftime("%Y-%m-%dT%H:%m:%S#{sprintf('%s%02d:%02d', (offset < 0 ? '-' : '+'), *(offset.abs / 60).divmod(60))}")
  end
end

class Float
  alias :to_str :to_s
  def to_s
     to_f % 1 == 0 ? to_i.to_s : to_str
  end
end

class IO
  def read__UI8(position = nil)
    seek position unless position.nil?
    readchar
  end
  
  def read__UI16(position = nil)
    seek position unless position.nil?
    (readchar << 8) + readchar
  end
  
  def read__UI24(position = nil)
    seek position unless position.nil?
    (readchar << 16) + (readchar << 8) + readchar
  end
  
  def read__UI32(position = nil)
    seek position unless position.nil?
    (readchar << 24) + (readchar << 16) + (readchar << 8) + readchar
  end
  
  def read__STRING(length, position = nil)
    seek position unless position.nil?
    read length
  end
  
  
  def write__UI8(value, position = nil)
    seek position unless position.nil?
    write [value].pack('C')
  end
  
  def write__UI24(value, position = nil)
    seek position unless position.nil?
    write [value >> 16].pack('c')
    write [(value >> 8) & 0xff].pack('c')
    write [value & 0xff].pack('c')
  end
  
  def write__UI32(value, position = nil)
    seek position unless position.nil?
    write [value].pack('N')
  end
  
  def write__STRING(string, position = nil)
    seek position unless position.nil?
    write string
  end
end

class ARGFWrapper
  def readchar
    ARGF.readchar
  end
  
  def read(length)
    ARGF.read(length)
  end
  
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
end
