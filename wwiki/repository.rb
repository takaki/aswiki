require 'wwiki/backup'
require 'delegate'

module WWiki
  class Repository < DelegateClass(Backup)
    def initialize(basedir)
      @dir = File.join(basedir ,'text')
      super(WWiki::Backup.new(basedir))
    end

    def read(name, id=nil) 
      return File.readlines(File.join(@dir,name))
    end
    
    def save(name, str)
      fname = File.join(@dir,name)
      STDERR.puts str
      backup(fname)
      (open(fname ,'w') << str.gsub(/\r\n/, "\n")).close
    end
    
    def mtime(name)
      return File.mtime(File.join(@dir,name))
    end

    def namelist
      return Dir.open(@dir).select{|f| test(?f, File.join(@dir, f) )}
    end
    
    def attrlist
      return Dir.open(@dir).select{|f| test(?f, File.join(@dir, f) )}.
	map{|f| [f, mtime(f)]}
    end
  end
end
