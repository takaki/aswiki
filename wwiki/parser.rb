require 'strscan'
require 'uri/common'
require 'delegate'

require 'wwiki/scanner'
require 'wwiki/node'

module WWiki
  class Parser
    WORD  = [:SPACE, :OTHER, :WORD]
    TAG = [:ENDPERIOD, :INTERWIKINAME, :WIKINAME1, :WIKINAME2, :URI,:MOINHREF]
    DECORATION = [:EM, :STRONG]
    TEXTLINE = WORD + TAG + [:EOL]
    PARAGRAPH = TEXTLINE + DECORATION 
    TEXT = PARAGRAPH + [:UL, :OL]
    D_TAG = {:EM => EmNode,  :STRONG => StrongNode}

    def initialize(str)
      @s = Scanner.new(str)
      @tree = parse
    end
    attr_reader :tree
    private 
    def next_token
      @token = @s.next_token
    end
    def parse
      @line = 1
      node = RootNode.new()
      next_token
      while true
	case @token[0]
	when *TEXT
	  node << text
	when :BLANK       
	  node << blank
	when :DL          
	  node << dl
	when :EOL         
	  eol  
	  node << "\n"
	when :HN_BEGIN    
	  node << hn
	when :HR          
	  node << HrNode.new
	  next_token
	when :PLUGIN  
	  node << plugin
	when :PLUGIN_BEGIN
	  node << plugin_block
	when :PRE_BEGIN   
	  node << preblock
	when :TABLE_BEGIN 
	  node << table
	when :EOF         
	  break
	else 
	  node << syntax_error
	end
      end 
      return node
    end
    def blank
      next_token
      while true
	case  @token[0]
	when :BLANK
	  next_token
	when :EOL  
	  eol
	else 
	  break
	end
      end
      return nil
    end
    def hn
      level = @token[1].size
      node = HNNode.new(level)
      next_token
      node << textline
      return  node
    end
    def plugin_block
      node  = nil
      block = [] << (@token[1]+"\n")
      block_b = @line
      if :EOL == next_token[0] then eol else node << syntax_error end
      block += textblock(:PLUGIN_END)
      while true
	case @token[0] 
	when :PLUGIN_END 
	  block << @token[1] 
	  next_token
	when :EOL 
	  eol 
	  break
	when :EOF
	  break
	else node << syntax_error
	end
      end
      block_e = @line 
      return node << @plugins.onview(@session, block, block_b, block_e)
    end
    def plugin
      node = @token[1]
      next_token
      return @plugins.onview(@session, [node.to_s], @line, 0)
    end

    def dl
      node = nil << "<dl>" 
      while true
	next_token
	node << "<dt>" << textline << "</dt>" <<"<dd>" << text  << "</dd>"
	case @token[0]
	when :DL 
	  next
	else node << "</dl>"
	  break
	end
      end
      return node 
    end
    def ul
      node = UlNode.new
      indent = @token[1].size
      next_token
      node << catch(:ulend) do
	while true
	  case @token[0]
	  when *TEXT
	    node << text(indent)
	  else
	    break
	  end
	end
      end
      return node 
    end
    def ol
      node = OlNode.new
      indent = @token[1].size
      next_token
      while true
	case @token[0]
	when *TEXT
	  node << text(indent)
	else
	  break
	end
      end
      return node
    end
    def table
      node = nil << "<table>" 
      while true
	case @token[0]
	when :TABLE_BEGIN
	  next_token
	  node << table_tr
	when :EOL
	  eol
	when :EOF
	  break
	else 
	  break
	end
      end
      node << '</table>'
      return node
    end
    def table_tr
      node = nil
      node << "<tr>"
      while true
	node << table_td
	case @token[0]
	when :TABLE_END
	  eol
	  break  # XXX
	else 
	  break
	end
      end
      return node << "</tr>\n"
    end
    def table_td
      node = nil
      while true
	node << "<td>" << text << "</td>"
	case @token[0]
	when :TABLE
	  next_token
	when :TABLE_END
	  break
	else  break
	end
      end
      return node
    end    
    def paragraph
      node = ParagraphNode.new
      while true
	case @token[0]
	when *TEXTLINE
	  node << textline
	when :STRONG
	  node << decorate(:STRONG)
	when :EM
	  node << decorate(:EM)
	else
	  break
	end
      end
      return node
    end
    def text(indent=0)
      node = TextNode.new
      while true
	case @token[0]
	when *PARAGRAPH
	  node << paragraph
	when :UL
	  if indent == @token[1].size
	    next_token
	    break
	  elsif indent < @token[1].size
	    node << ul
	  elsif indent > @token[1].size
	    throw :ulend, node # XXX ???
	  else
	    raise
	  end
	when :OL          
	  if indent == @token[1].size
	    next_token
	    break
	  elsif indent < @token[1].size
	    node << ol
	  elsif indent > @token[1].size
	    break
	  else
	    raise
	  end
	else
	  break
	end
      end
      return node
    end
    def decorate(tag)
      next_token
      node = D_TAG[tag].new
      node  << textline
      if @token[0] == tag 
	next_token
      else                
	node << syntax_error
      end
      return node 
    end

    def textline
      node = TextlineNode.new
      while true
	case @token[0]
	when :OTHER, :SPACE, :WORD
	  node << @token[1]
	when :WIKINAME1,:INTERWIKINAME
	  node << WikinameNode.new # (@token[1])
	when :WIKINAME2
	  name = @token[1][2..-3]
	  node << WikinameNode.new # (name)
	when :URI
	  node << ahref(@token[1],CGI::escapeHTML(@token[1]))
	when :MOINHREF
	  url, key = @token[1][1..-2].split
	  url = CGI::unescapeHTML(url)
	  if /\Aimg:/ =~ url then  node << %Q|<img src="#{$'}" alt="#{key}">|
	  else node << ahref(url, CGI::escapeHTML(key))
	  end
	when :ENDPERIOD
	  node << "<br>"
	when :EOL
	  eol
	  node << "\n" 
	  break
	else
	  break
	end
	next_token
      end
      return node
    end
    def textblock(endtag)
      node = []
      line = ""
      while true
	case @token[0]
	when :EOF   
	  break
	when :EOL   
	  line << "\n" 
	  node << line 
	  line = ""
	  eol 
	when endtag 
	  next_token
	  break
	else line << @token[1] 
	  next_token
	end
      end
      return node
    end
    def preblock
      node = PreNode.new
      next_token
      node << textblock(:PRE_END).to_s
      return node 
    end
    def eol
      @line +=1
      next_token
      return 
    end
    def syntax_error
      s = "(Syntax error at line #{@line}. ; #{@token.inspect})\n" 
	next_token 
      return s
    end
  end
end

