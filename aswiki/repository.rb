# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/backup'
require 'aswiki/util'
require 'aswiki/revlink'
require 'aswiki/parser'

module AsWiki
  class Repository
    def initialize(dir=$DIR_TEXT)
      @dir = dir
    end

    def exist?(name)
      return File.exist?(textname(name))
    end

    def load(name, id=nil) 
      return File.readlines(textname(name))
    end
    
    def save(name, str)
      (open(textname(name),'w') << str.gsub(/\r\n/, "\n")).close
      RevLink.new.regist(name,
			 AsWiki::Parser.new(FileScanner[name], name).
			 wikinames.uniq.
			 delete_if{|n| n =~ /\A\w+:[A-Z]\w+(?!:)/})
      
      backup = AsWiki::Backup.new
      backup.ci(name)
      if File.size(textname(name)) <= 1
	File.unlink(textname(name))
      end
    end
  
    def mtime(name)
      if exist?(name)
	return File.mtime(textname(name))
      else
	return nil
      end
    end

    def namelist
      return Dir.open(@dir).select{|f| test(?f, File.join(@dir, f))}.
	map{|f| AsWiki::unescape(f)}
    end
    
    def attrlist
      return Dir.open(@dir).select{|f| test(?f, File.join(@dir, f))}.
	map{|f| [AsWiki::unescape(f), File.mtime(File.join(@dir, f))]}
    end
    def textname(name)
      return File.join(@dir, AsWiki::escape(name)).untaint
    end
    private
  end
end
