# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/plugin'
require 'aswiki/attachdb'
require 'cgi/session'
require 'bdb'

module AsWiki
  class AttachPlugin < Plugin
    Name = 'attach'
    def onpost(session, file)
      pname = session['pname']
      adb =  AsWiki::AttachDB.new
      adb.savefile(pname, file[0])
    end
    def onview(line, b, e, av=[])
      session = CGI::Session.new(CGI::new, {'tmpdir' => 'session',
				   'new_session'=>true})
      session['pname'] = @name
      session['plugin'] = self.type

      adb =  AsWiki::AttachDB.new
      @data ={:_session_id => session.session_id,
	:item => adb.listfile(@name)
      }
      # @view = load_template.expand_tree(data)
      load_parts
    end
    attr_reader :data
  end
end

