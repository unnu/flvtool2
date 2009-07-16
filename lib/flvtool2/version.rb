module FLVTool2

  PROGRAMM_VERSION = [1, 0, 6]
  PROGRAMM_VERSION_EXTENSION = ''
  
  def self.version
    "#{PROGRAMM_VERSION.join('.')}#{PROGRAMM_VERSION_EXTENSION}"
  end  
end

