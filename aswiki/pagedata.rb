# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/parser'
require "aswiki/i18n/#{$LANG}"

module AsWiki
  class PageData
    include AsWiki::Util
    include Amrita::ExpandByMember
    include AsWiki::I18N

    def initialize(name)
      @name = name
      @r = AsWiki::Repository.new('.')

      @title       = name
      @edit        = cgiurl([['c', 'e'], ['p', name]])
      @toppage     = cgiurl([['c', 'v'], ['p', $TOPPAGENAME]])
      @recentpages = cgiurl([['c', 'v'], ['p', 'RecentPages']])
      @allpages    = cgiurl([['c', 'v'], ['p', 'AllPages']])
      @rawpage     = cgiurl([['c', 'r'], ['p', name]])
      @historypage = cgiurl([['c', 'h'], ['p', name]])
      @diffpage    = cgiurl([['c', 'd'], ['p', name]])
      @helppage    = cgiurl([['c', 'v'], ['p', 'HelpPage']])

    end
    attr_reader :tree, :wikinames
    attr_reader :edit,:recentpages,:toppage,:allpages,:rawpage,
      :diffpage,:helppage, :historypage, :name
    attr_accessor :revision, :timestamp, :body, :md5sum, :title
    def parsefile
      c = @r.load(@name)
      @timestamp = @r.mtime(@name)
      parsetext(c.to_s)
      # @p = AsWiki::Parser.new(c.to_s, @name)
      # @wikinames = @p.wikinames
      # @body = @p.tree
    end
    def parsetext(c)
      @p = AsWiki::Parser.new(c.to_s, @name)
      @wikinames = @p.wikinames
      @body = @p.tree
    end

    def lastmodified
      timestr(@timestamp)
    end
    def wikilinks
       return @p.wikinames.delete_if{|w| w =~ /:[^:]/ }.uniq.map{|l| 
 	  [l, @r.mtime(l)]}.sort{|a,b| b[1].to_i <=> a[1].to_i}.map{|l|
	{:pname => wikilink(CGI::escapeHTML(l[0]),@name) ,
	  :modified =>  modified(l[1])  }}
    end

    def logtable
      backup = AsWiki::Backup.new('.')
      logtable = backup.rlog(@name).map{|l| 
	{ :revision => {:url=> cgiurl([['c','h'], ['p',@name], ['rev',l[0]]]),
	    :rev => l[0]},
	  :diffline => l[2].to_s,
	  :timestamp => timestr(l[1]),
	  :tonew => {:url =>  cgiurl([['c', 'd'], ['p', @name], ['rn',0],
				       ['ro',l[0]]]),
	    :text => "current - #{l[0]}"},
	  :toold => l[0] != 1 ?  {
	    :url => cgiurl([['c','d'], ['p', @name], ['rn', l[0]],
			     ['ro', l[0]-1]]),
	    :text => "new #{l[0]} old #{l[0]-1}" }  : 'not avail'
	}
      }
    end
  end
end
