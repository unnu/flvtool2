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

class MiXML

  def self.parse(xml)
    current = {}
    xml.scan( /<([!\?].*?)>|<([^\/].*?)>|<\/(.+?)>|([^<>]*)/m ) do |ignore, open_tag, close_tag, cdata|  
      if open_tag
        tag_name = open_tag.match( /(\w+)\s?/ )[1]
        
        parameters = {}
        open_tag.scan( /(\w+)=\"(.*?)\"/ ) { |key, value| parameters[key] = value }

        parameters[:parent] = current
        
        if current[tag_name].class == Array
          current[tag_name] << parameters
          current = current[tag_name].last
        else
          if current[tag_name]
            current[tag_name] = [ current[tag_name], parameters ]
            current = current[tag_name].last
          else
            current[tag_name] = parameters
            current = current[tag_name]
          end
        end
        
      elsif close_tag
        parent = current[:parent]
        current.delete( :parent )
        current = parent unless parent.nil?
      elsif cdata
        cdata.strip!
        current[:cdata] = cdata unless cdata.empty?
      end
    end

    return normalize_cdata( current )
  end

  def self.normalize_cdata(branch)
    if branch.class == Array
      branch.collect do |item|
        normalize_cdata( item )
      end
    elsif branch.class == Hash && branch[:cdata].nil?
      branch.inject( {} ) do |hash, key_value|
        key, value = key_value
        value = normalize_cdata( value )
        hash[key] = value
        hash
      end
    else
      if branch[:cdata] && branch.size == 1
        branch[:cdata]
      else
        branch
      end
    end
  end
  
  def self.dump(object, indent = 0)
    '  ' * indent << dump_object(object, indent).strip
  end
  
  def self.dump_object(object, indent = 0)
    xml = ''
    
    if object.class == Object
      object = object.instance_variables.inject( {} ) { |hash, var| hash[var.gsub('@', '')] = object.instance_variable_get(var); hash }
    end
    
    case object
    when Array
      object.each do |value|
        xml << indenter(indent) << "<value>" << dump_object( value, indent + 1 ) << "</value>"
      end
      xml << indenter(indent - 1)
    when Hash
      object.each do |key, value|
        xml << indenter(indent) << "<#{key}>" << dump_object( value, indent + 1 ) << "</#{key}>"
      end
      xml << indenter(indent - 1)
    else
      xml << object.to_s
    end
    
    return xml
  end

  def self.indenter(indent = 0)
    "\n" << '  ' * indent
  end
end

