class CodeTools::PegParser
  # :stopdoc:

    # This is distinct from setup_parser so that a standalone parser
    # can redefine #initialize and still have access to the proper
    # parser setup code.
    def initialize(str, debug=false)
      setup_parser(str, debug)
    end



    # Prepares for parsing +str+.  If you define a custom initialize you must
    # call this method before #parse
    def setup_parser(str, debug=false)
      set_string str, 0
      @memoizations = Hash.new { |h,k| h[k] = {} }
      @result = nil
      @failed_rule = nil
      @failing_rule_offset = -1

      setup_foreign_grammar
    end

    attr_reader :string
    attr_reader :failing_rule_offset
    attr_accessor :result, :pos

    def current_column(target=pos)
      if c = string.rindex("\n", target-1)
        return target - c - 1
      end

      target + 1
    end

    def current_line(target=pos)
      cur_offset = 0
      cur_line = 0

      string.each_line do |line|
        cur_line += 1
        cur_offset += line.size
        return cur_line if cur_offset >= target
      end

      -1
    end

    def lines
      lines = []
      string.each_line { |l| lines << l }
      lines
    end



    def get_text(start)
      @string[start..@pos-1]
    end

    # Sets the string and current parsing position for the parser.
    def set_string string, pos
      @string = string
      @string_size = string ? string.size : 0
      @pos = pos
    end

    def show_pos
      width = 10
      if @pos < width
        "#{@pos} (\"#{@string[0,@pos]}\" @ \"#{@string[@pos,width]}\")"
      else
        "#{@pos} (\"... #{@string[@pos - width, width]}\" @ \"#{@string[@pos,width]}\")"
      end
    end

    def failure_info
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "line #{l}, column #{c}: failed rule '#{info.name}' = '#{info.rendered}'"
      else
        "line #{l}, column #{c}: failed rule '#{@failed_rule}'"
      end
    end

    def failure_caret
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      line = lines[l-1]
      "#{line}\n#{' ' * (c - 1)}^"
    end

    def failure_character
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset
      lines[l-1][c-1, 1]
    end

    def failure_oneline
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      char = lines[l-1][c-1, 1]

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "@#{l}:#{c} failed rule '#{info.name}', got '#{char}'"
      else
        "@#{l}:#{c} failed rule '#{@failed_rule}', got '#{char}'"
      end
    end

    class ParseError < RuntimeError
    end

    def raise_error
      raise ParseError, failure_oneline
    end

    def show_error(io=STDOUT)
      error_pos = @failing_rule_offset
      line_no = current_line(error_pos)
      col_no = current_column(error_pos)

      io.puts "On line #{line_no}, column #{col_no}:"

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        io.puts "Failed to match '#{info.rendered}' (rule '#{info.name}')"
      else
        io.puts "Failed to match rule '#{@failed_rule}'"
      end

      io.puts "Got: #{string[error_pos,1].inspect}"
      line = lines[line_no-1]
      io.puts "=> #{line}"
      io.print(" " * (col_no + 3))
      io.puts "^"
    end

    def set_failed_rule(name)
      if @pos > @failing_rule_offset
        @failed_rule = name
        @failing_rule_offset = @pos
      end
    end

    attr_reader :failed_rule

    def match_string(str)
      len = str.size
      if @string[pos,len] == str
        @pos += len
        return str
      end

      return nil
    end

    def scan(reg)
      if m = reg.match(@string[@pos..-1])
        width = m.end(0)
        @pos += width
        return true
      end

      return nil
    end

    if "".respond_to? :ord
      def get_byte
        if @pos >= @string_size
          return nil
        end

        s = @string[@pos].ord
        @pos += 1
        s
      end
    else
      def get_byte
        if @pos >= @string_size
          return nil
        end

        s = @string[@pos]
        @pos += 1
        s
      end
    end

    def parse(rule=nil)
      # We invoke the rules indirectly via apply
      # instead of by just calling them as methods because
      # if the rules use left recursion, apply needs to
      # manage that.

      if !rule
        apply(:_root)
      else
        method = rule.gsub("-","_hyphen_")
        apply :"_#{method}"
      end
    end

    class MemoEntry
      def initialize(ans, pos)
        @ans = ans
        @pos = pos
        @result = nil
        @set = false
        @left_rec = false
      end

      attr_reader :ans, :pos, :result, :set
      attr_accessor :left_rec

      def move!(ans, pos, result)
        @ans = ans
        @pos = pos
        @result = result
        @set = true
        @left_rec = false
      end
    end

    def external_invoke(other, rule, *args)
      old_pos = @pos
      old_string = @string

      set_string other.string, other.pos

      begin
        if val = __send__(rule, *args)
          other.pos = @pos
          other.result = @result
        else
          other.set_failed_rule "#{self.class}##{rule}"
        end
        val
      ensure
        set_string old_string, old_pos
      end
    end

    def apply_with_args(rule, *args)
      memo_key = [rule, args]
      if m = @memoizations[memo_key][@pos]
        @pos = m.pos
        if !m.set
          m.left_rec = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        m = MemoEntry.new(nil, @pos)
        @memoizations[memo_key][@pos] = m
        start_pos = @pos

        ans = __send__ rule, *args

        lr = m.left_rec

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr
          return grow_lr(rule, args, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def apply(rule)
      if m = @memoizations[rule][@pos]
        @pos = m.pos
        if !m.set
          m.left_rec = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        m = MemoEntry.new(nil, @pos)
        @memoizations[rule][@pos] = m
        start_pos = @pos

        ans = __send__ rule

        lr = m.left_rec

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr
          return grow_lr(rule, nil, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def grow_lr(rule, args, start_pos, m)
      while true
        @pos = start_pos
        @result = m.result

        if args
          ans = __send__ rule, *args
        else
          ans = __send__ rule
        end
        return nil unless ans

        break if @pos <= m.pos

        m.move! ans, @pos, @result
      end

      @result = m.result
      @pos = m.pos
      return m.ans
    end

    class RuleInfo
      def initialize(name, rendered)
        @name = name
        @rendered = rendered
      end

      attr_reader :name, :rendered
    end

    def self.rule_info(name, rendered)
      RuleInfo.new(name, rendered)
    end


  # :startdoc:

 #%
  attr_accessor :builder
  attr_accessor :root_node
  
  # Generate an AST::Node of the given type (generated by the @builder)
  def node type, locator, *args
    @builder.__send__ type, locator, *args
  end
  
  # Generate a Token with the given type, text, and row_col
  def token type, text, row_col=nil
    row_col ||= [current_line, current_column-text.length]
    Token.new type, text, row_col
  end
  
  # A token is a lightweight unit of text with type and location info
  # as well as some convenience function for common conversion operations.
  class Token
    attr_accessor :type
    attr_accessor :text
    attr_accessor :line
    
    def inspect
      [@type, @text, @line].inspect
    end
    alias_method :to_s, :inspect
    
    def initialize type, text, row_col
      @type = type
      @text = text
      # TODO: integrate columns from location instead of just rows
      @line = row_col.first
    end
    
    def sym;      @text.to_sym    end
    def float;    Float(@text)    end
    def integer;  Integer(@text)  end
  end




#%
  # Encode escape characters in string literals
  # TODO: rigorously test and refine
  #
  def encode_escapes str
    str.gsub /\\(.)/ do
      case $1
      when "a"; "\a" # \a  0x07  Bell or alert
      when "b"; "\b" # \b  0x08  Backspace
      # TODO:        # \cx       Control-x
      # TODO:        # \C-x      Control-x
      when "e"; "\e" # \e  0x1b  Escape
      when "f"; "\f" # \f  0x0c  Formfeed
      # TODO:        # \M-\C-x   Meta-Control-x
      when "n"; "\n" # \n  0x0a  Newline
      # TODO:        # \nnn      Octal notation, where n is a digit
      when "r"; "\r" # \r  0x0d  Carriage return
      when "s"; "\s" # \s  0x20  Space
      when "t"; "\t" # \t  0x09  Tab
      when "v"; "\v" # \v  0x0b  Vertical tab
      # TODO:        # \xnn      Hexadecimal notation, where n is a digit
      else; "#{$1}"
      end
    end
  end
  
  # Given a node,op list ([node, op, node, op, ... node]) and operator types,
  # collapse the (node, op, node) groups where the operator is one of the types
  #
  # This function is meant to be called several times on the same list,
  # with a different set of operator types each time, in order of precedence.
  #
  def collapse input, *types
    output = []
    
    # Scan through, reducing or shifting based on the operator
    while input.count > 2
      n0 = input.shift
      op = input.shift
      
      if types.include? op.type
        n1 = input.shift
        
        result = block_given? ?
          yield(n0,op,n1) :
          node(:invoke, op, n0, op.sym, node(:argass, n1, [n1]))
        input.unshift result
      else
        output.push n0
        output.push op
      end
    end
    
    # Push the last item remaining
    output.push input.shift
    
    input.replace output
  end


  # :stopdoc:
  def setup_foreign_grammar; end

  # root = declobj_expr_body:n0 { @root_node = node(:declfile, n0, n0) }
  def _root

    _save = self.pos
    while true # sequence
      _tmp = apply(:_declobj_expr_body)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  @root_node = node(:declfile, n0, n0) ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_root unless _tmp
    return _tmp
  end

  # decl = (declobj | declstr | copen)
  def _decl

    _save = self.pos
    while true # choice
      _tmp = apply(:_declobj)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_declstr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_copen)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_decl unless _tmp
    return _tmp
  end

  # declobj_expr = (category | declobj_expr_not_category)
  def _declobj_expr

    _save = self.pos
    while true # choice
      _tmp = apply(:_category)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_declobj_expr_not_category)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_declobj_expr unless _tmp
    return _tmp
  end

  # declobj_expr_not_category = (decl | cdefn | cmeme | constant | meme)
  def _declobj_expr_not_category

    _save = self.pos
    while true # choice
      _tmp = apply(:_decl)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_cdefn)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_cmeme)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_constant)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_meme)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_declobj_expr_not_category unless _tmp
    return _tmp
  end

  # meme_expr = arg_expr
  def _meme_expr
    _tmp = apply(:_arg_expr)
    set_failed_rule :_meme_expr unless _tmp
    return _tmp
  end

  # arg_expr = (assignment | left_chained_atoms | dyn_string | dyn_symstr | expr_atom)
  def _arg_expr

    _save = self.pos
    while true # choice
      _tmp = apply(:_assignment)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_left_chained_atoms)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_dyn_string)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_dyn_symstr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_expr_atom)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_arg_expr unless _tmp
    return _tmp
  end

  # expr_atom = (decl | left_chained_invocations | lit_string | lit_symstr | unary_operation | paren_expr | constant | lit_simple | lit_array | invoke)
  def _expr_atom

    _save = self.pos
    while true # choice
      _tmp = apply(:_decl)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_left_chained_invocations)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_string)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_symstr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_unary_operation)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_paren_expr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_constant)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_simple)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_array)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_invoke)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_expr_atom unless _tmp
    return _tmp
  end

  # expr_atom_not_chained = (decl | lit_string | lit_symstr | unary_operation | paren_expr | constant | lit_simple | lit_array | invoke)
  def _expr_atom_not_chained

    _save = self.pos
    while true # choice
      _tmp = apply(:_decl)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_string)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_symstr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_unary_operation)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_paren_expr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_constant)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_simple)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_array)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_invoke)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_expr_atom_not_chained unless _tmp
    return _tmp
  end

  # expr_atom_not_string = (decl | left_chained_invocations | unary_operation | paren_expr | constant | lit_simple | lit_array | invoke)
  def _expr_atom_not_string

    _save = self.pos
    while true # choice
      _tmp = apply(:_decl)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_left_chained_invocations)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_unary_operation)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_paren_expr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_constant)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_simple)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_array)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_invoke)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_expr_atom_not_string unless _tmp
    return _tmp
  end

  # eol_comment = "#" (!c_eol .)*
  def _eol_comment

    _save = self.pos
    while true # sequence
      _tmp = match_string("#")
      unless _tmp
        self.pos = _save
        break
      end
      while true

        _save2 = self.pos
        while true # sequence
          _save3 = self.pos
          _tmp = apply(:_c_eol)
          _tmp = _tmp ? nil : true
          self.pos = _save3
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = get_byte
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_eol_comment unless _tmp
    return _tmp
  end

  # c_nl = "\n"
  def _c_nl
    _tmp = match_string("\n")
    set_failed_rule :_c_nl unless _tmp
    return _tmp
  end

  # c_spc = (/[ \t\r\f\v]/ | "\\\n" | eol_comment)
  def _c_spc

    _save = self.pos
    while true # choice
      _tmp = scan(/\A(?-mix:[ \t\r\f\v])/)
      break if _tmp
      self.pos = _save
      _tmp = match_string("\\\n")
      break if _tmp
      self.pos = _save
      _tmp = apply(:_eol_comment)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_c_spc unless _tmp
    return _tmp
  end

  # c_spc_nl = (c_spc | c_nl)
  def _c_spc_nl

    _save = self.pos
    while true # choice
      _tmp = apply(:_c_spc)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_c_nl)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_c_spc_nl unless _tmp
    return _tmp
  end

  # c_eof = !.
  def _c_eof
    _save = self.pos
    _tmp = get_byte
    _tmp = _tmp ? nil : true
    self.pos = _save
    set_failed_rule :_c_eof unless _tmp
    return _tmp
  end

  # c_eol = (c_nl | c_eof)
  def _c_eol

    _save = self.pos
    while true # choice
      _tmp = apply(:_c_nl)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_c_eof)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_c_eol unless _tmp
    return _tmp
  end

  # c_any = .
  def _c_any
    _tmp = get_byte
    set_failed_rule :_c_any unless _tmp
    return _tmp
  end

  # c_upper = /[[:upper:]]/
  def _c_upper
    _tmp = scan(/\A(?-mix:[[:upper:]])/)
    set_failed_rule :_c_upper unless _tmp
    return _tmp
  end

  # c_lower = (/[[:lower:]]/ | "_")
  def _c_lower

    _save = self.pos
    while true # choice
      _tmp = scan(/\A(?-mix:[[:lower:]])/)
      break if _tmp
      self.pos = _save
      _tmp = match_string("_")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_c_lower unless _tmp
    return _tmp
  end

  # c_num = /[0-9]/
  def _c_num
    _tmp = scan(/\A(?-mix:[0-9])/)
    set_failed_rule :_c_num unless _tmp
    return _tmp
  end

  # c_alpha = (c_lower | c_upper)
  def _c_alpha

    _save = self.pos
    while true # choice
      _tmp = apply(:_c_lower)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_c_upper)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_c_alpha unless _tmp
    return _tmp
  end

  # c_alnum = (c_alpha | c_num)
  def _c_alnum

    _save = self.pos
    while true # choice
      _tmp = apply(:_c_alpha)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_c_num)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_c_alnum unless _tmp
    return _tmp
  end

  # c_suffix = ("!" | "?")
  def _c_suffix

    _save = self.pos
    while true # choice
      _tmp = match_string("!")
      break if _tmp
      self.pos = _save
      _tmp = match_string("?")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_c_suffix unless _tmp
    return _tmp
  end

  # t_CONST_SEP = < "," > {token(:t_CONST_SEP,     text)}
  def _t_CONST_SEP

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string(",")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_CONST_SEP,     text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_CONST_SEP unless _tmp
    return _tmp
  end

  # t_EXPR_SEP = < (";" | c_nl) > {token(:t_EXPR_SEP,      text)}
  def _t_EXPR_SEP

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = match_string(";")
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_c_nl)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_EXPR_SEP,      text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_EXPR_SEP unless _tmp
    return _tmp
  end

  # t_ARG_SEP = < ("," | c_nl) > {token(:t_ARG_SEP,       text)}
  def _t_ARG_SEP

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = match_string(",")
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_c_nl)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_ARG_SEP,       text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_ARG_SEP unless _tmp
    return _tmp
  end

  # t_DECLARE_BEGIN = < "{" > {token(:t_DECLARE_BEGIN, text)}
  def _t_DECLARE_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("{")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_DECLARE_BEGIN, text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_DECLARE_BEGIN unless _tmp
    return _tmp
  end

  # t_DECLARE_END = < ("}" | c_eof) > {token(:t_DECLARE_END,   text)}
  def _t_DECLARE_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = match_string("}")
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_c_eof)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_DECLARE_END,   text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_DECLARE_END unless _tmp
    return _tmp
  end

  # t_MEME_MARK = < ":" > {token(:t_MEME_MARK,     text)}
  def _t_MEME_MARK

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string(":")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_MEME_MARK,     text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_MEME_MARK unless _tmp
    return _tmp
  end

  # t_MEME_BEGIN = < "{" > {token(:t_MEME_BEGIN,    text)}
  def _t_MEME_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("{")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_MEME_BEGIN,    text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_MEME_BEGIN unless _tmp
    return _tmp
  end

  # t_MEME_END = < "}" > {token(:t_MEME_END,      text)}
  def _t_MEME_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("}")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_MEME_END,      text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_MEME_END unless _tmp
    return _tmp
  end

  # t_PAREN_BEGIN = < "(" > {token(:t_PAREN_BEGIN,   text)}
  def _t_PAREN_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("(")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_PAREN_BEGIN,   text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_PAREN_BEGIN unless _tmp
    return _tmp
  end

  # t_PAREN_END = < ")" > {token(:t_PAREN_END,     text)}
  def _t_PAREN_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string(")")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_PAREN_END,     text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_PAREN_END unless _tmp
    return _tmp
  end

  # t_DEFINE = < "<" > {token(:t_DEFINE,        text)}
  def _t_DEFINE

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("<")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_DEFINE,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_DEFINE unless _tmp
    return _tmp
  end

  # t_REOPEN = < "<<" > {token(:t_REOPEN,        text)}
  def _t_REOPEN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("<<")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_REOPEN,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_REOPEN unless _tmp
    return _tmp
  end

  # t_PARAMS_BEGIN = < "|" > {token(:t_PARAMS_BEGIN,  text)}
  def _t_PARAMS_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("|")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_PARAMS_BEGIN,  text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_PARAMS_BEGIN unless _tmp
    return _tmp
  end

  # t_PARAMS_END = < "|" > {token(:t_PARAMS_END,    text)}
  def _t_PARAMS_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("|")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_PARAMS_END,    text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_PARAMS_END unless _tmp
    return _tmp
  end

  # t_ARGS_BEGIN = < "(" > {token(:t_ARGS_BEGIN,    text)}
  def _t_ARGS_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("(")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_ARGS_BEGIN,    text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_ARGS_BEGIN unless _tmp
    return _tmp
  end

  # t_ARGS_END = < ")" > {token(:t_ARGS_END,      text)}
  def _t_ARGS_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string(")")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_ARGS_END,      text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_ARGS_END unless _tmp
    return _tmp
  end

  # t_ARRAY_BEGIN = < "[" > {token(:t_ARRAY_BEGIN,   text)}
  def _t_ARRAY_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("[")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_ARRAY_BEGIN,   text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_ARRAY_BEGIN unless _tmp
    return _tmp
  end

  # t_ARRAY_END = < "]" > {token(:t_ARRAY_END,     text)}
  def _t_ARRAY_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("]")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_ARRAY_END,     text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_ARRAY_END unless _tmp
    return _tmp
  end

  # t_CONSTANT = < c_upper c_alnum* > {token(:t_CONSTANT,      text)}
  def _t_CONSTANT

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_c_upper)
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_alnum)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_CONSTANT,      text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_CONSTANT unless _tmp
    return _tmp
  end

  # t_IDENTIFIER = < c_lower c_alnum* c_suffix? > {token(:t_IDENTIFIER,    text)}
  def _t_IDENTIFIER

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_c_lower)
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_alnum)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos
        _tmp = apply(:_c_suffix)
        unless _tmp
          _tmp = true
          self.pos = _save3
        end
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_IDENTIFIER,    text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_IDENTIFIER unless _tmp
    return _tmp
  end

  # t_SYMBOL = ":" < c_lower c_alnum* > {token(:t_SYMBOL,        text)}
  def _t_SYMBOL

    _save = self.pos
    while true # sequence
      _tmp = match_string(":")
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_c_lower)
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_alnum)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_SYMBOL,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_SYMBOL unless _tmp
    return _tmp
  end

  # t_NULL = < "null" > {token(:t_NULL,          text)}
  def _t_NULL

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("null")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_NULL,          text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_NULL unless _tmp
    return _tmp
  end

  # t_VOID = < "void" > {token(:t_VOID,          text)}
  def _t_VOID

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("void")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_VOID,          text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_VOID unless _tmp
    return _tmp
  end

  # t_TRUE = < "true" > {token(:t_TRUE,          text)}
  def _t_TRUE

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("true")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_TRUE,          text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_TRUE unless _tmp
    return _tmp
  end

  # t_FALSE = < "false" > {token(:t_FALSE,         text)}
  def _t_FALSE

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("false")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_FALSE,         text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_FALSE unless _tmp
    return _tmp
  end

  # t_SELF = < "self" > {token(:t_SELF,          text)}
  def _t_SELF

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("self")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_SELF,          text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_SELF unless _tmp
    return _tmp
  end

  # t_FLOAT = < "-"? c_num+ "." c_num+ > {token(:t_FLOAT,         text)}
  def _t_FLOAT

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _save2 = self.pos
        _tmp = match_string("-")
        unless _tmp
          _tmp = true
          self.pos = _save2
        end
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos
        _tmp = apply(:_c_num)
        if _tmp
          while true
            _tmp = apply(:_c_num)
            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save3
        end
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(".")
        unless _tmp
          self.pos = _save1
          break
        end
        _save4 = self.pos
        _tmp = apply(:_c_num)
        if _tmp
          while true
            _tmp = apply(:_c_num)
            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save4
        end
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_FLOAT,         text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_FLOAT unless _tmp
    return _tmp
  end

  # t_INTEGER = < "-"? c_num+ > {token(:t_INTEGER,       text)}
  def _t_INTEGER

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _save2 = self.pos
        _tmp = match_string("-")
        unless _tmp
          _tmp = true
          self.pos = _save2
        end
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos
        _tmp = apply(:_c_num)
        if _tmp
          while true
            _tmp = apply(:_c_num)
            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save3
        end
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_INTEGER,       text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_INTEGER unless _tmp
    return _tmp
  end

  # t_DOT = < "." > {token(:t_DOT,           text)}
  def _t_DOT

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string(".")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_DOT,           text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_DOT unless _tmp
    return _tmp
  end

  # t_QUEST = < "." c_spc_nl* "?" > {token(:t_QUEST,         text)}
  def _t_QUEST

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _tmp = match_string(".")
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("?")
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_QUEST,         text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_QUEST unless _tmp
    return _tmp
  end

  # t_SCOPE = < "::" > {token(:t_SCOPE,         text)}
  def _t_SCOPE

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("::")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_SCOPE,         text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_SCOPE unless _tmp
    return _tmp
  end

  # t_ASSIGN = < "=" > {token(:t_ASSIGN,        text)}
  def _t_ASSIGN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("=")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_ASSIGN,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_ASSIGN unless _tmp
    return _tmp
  end

  # t_OP_TOPROC = < "&" > {token(:t_OP_TOPROC,     text)}
  def _t_OP_TOPROC

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("&")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_TOPROC,     text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_TOPROC unless _tmp
    return _tmp
  end

  # t_OP_NOT = < "!" > {token(:t_OP_NOT,        text)}
  def _t_OP_NOT

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("!")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_NOT,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_NOT unless _tmp
    return _tmp
  end

  # t_OP_PLUS = < "+" > {token(:t_OP_PLUS,       text)}
  def _t_OP_PLUS

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("+")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_PLUS,       text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_PLUS unless _tmp
    return _tmp
  end

  # t_OP_MINUS = < "-" > {token(:t_OP_MINUS,      text)}
  def _t_OP_MINUS

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("-")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_MINUS,      text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_MINUS unless _tmp
    return _tmp
  end

  # t_OP_MULT = < "*" > {token(:t_OP_MULT,       text)}
  def _t_OP_MULT

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("*")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_MULT,       text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_MULT unless _tmp
    return _tmp
  end

  # t_OP_DIV = < "/" > {token(:t_OP_DIV,        text)}
  def _t_OP_DIV

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("/")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_DIV,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_DIV unless _tmp
    return _tmp
  end

  # t_OP_MOD = < "%" > {token(:t_OP_MOD,        text)}
  def _t_OP_MOD

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("%")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_MOD,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_MOD unless _tmp
    return _tmp
  end

  # t_OP_EXP = < "**" > {token(:t_OP_EXP,        text)}
  def _t_OP_EXP

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("**")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_EXP,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_EXP unless _tmp
    return _tmp
  end

  # t_OP_AND = < "&&" > {token(:t_OP_AND,        text)}
  def _t_OP_AND

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("&&")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_AND,        text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_AND unless _tmp
    return _tmp
  end

  # t_OP_OR = < "||" > {token(:t_OP_OR,         text)}
  def _t_OP_OR

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("||")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_OR,         text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_OR unless _tmp
    return _tmp
  end

  # t_OP_AND_Q = < "&?" > {token(:t_OP_AND_Q,      text)}
  def _t_OP_AND_Q

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("&?")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_AND_Q,      text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_AND_Q unless _tmp
    return _tmp
  end

  # t_OP_OR_Q = < "|?" > {token(:t_OP_OR_Q,       text)}
  def _t_OP_OR_Q

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("|?")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_OR_Q,       text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_OR_Q unless _tmp
    return _tmp
  end

  # t_OP_VOID_Q = < "??" > {token(:t_OP_VOID_Q,     text)}
  def _t_OP_VOID_Q

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("??")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_VOID_Q,     text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_VOID_Q unless _tmp
    return _tmp
  end

  # t_OP_COMPARE = < ("<=>" | "=~" | "==" | "<=" | ">=" | "<" | ">") > {token(:t_OP_COMPARE,    text)}
  def _t_OP_COMPARE

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = match_string("<=>")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("=~")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("==")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("<=")
        break if _tmp
        self.pos = _save1
        _tmp = match_string(">=")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("<")
        break if _tmp
        self.pos = _save1
        _tmp = match_string(">")
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_OP_COMPARE,    text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_OP_COMPARE unless _tmp
    return _tmp
  end

  # string_norm = /[^\\\"]/
  def _string_norm
    _tmp = scan(/\A(?-mix:[^\\\"])/)
    set_failed_rule :_string_norm unless _tmp
    return _tmp
  end

  # t_STRING_BODY = < string_norm* ("\\" c_any string_norm*)* > {token(:t_STRING_BODY,   text)}
  def _t_STRING_BODY

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_string_norm)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        while true

          _save4 = self.pos
          while true # sequence
            _tmp = match_string("\\")
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = apply(:_c_any)
            unless _tmp
              self.pos = _save4
              break
            end
            while true
              _tmp = apply(:_string_norm)
              break unless _tmp
            end
            _tmp = true
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_STRING_BODY,   text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_STRING_BODY unless _tmp
    return _tmp
  end

  # t_STRING_BEGIN = < "\"" > {token(:t_STRING_BEGIN,  text)}
  def _t_STRING_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("\"")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_STRING_BEGIN,  text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_STRING_BEGIN unless _tmp
    return _tmp
  end

  # t_STRING_END = < "\"" > {token(:t_STRING_END,    text)}
  def _t_STRING_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("\"")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_STRING_END,    text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_STRING_END unless _tmp
    return _tmp
  end

  # t_SYMSTR_BEGIN = < ":\"" > {token(:t_SYMSTR_BEGIN,  text)}
  def _t_SYMSTR_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string(":\"")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_SYMSTR_BEGIN,  text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_SYMSTR_BEGIN unless _tmp
    return _tmp
  end

  # sstring_norm = /[^\\\']/
  def _sstring_norm
    _tmp = scan(/\A(?-mix:[^\\\'])/)
    set_failed_rule :_sstring_norm unless _tmp
    return _tmp
  end

  # t_SSTRING_BODY = < sstring_norm* ("\\" c_any sstring_norm*)* > {token(:t_SSTRING_BODY,  text)}
  def _t_SSTRING_BODY

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_sstring_norm)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        while true

          _save4 = self.pos
          while true # sequence
            _tmp = match_string("\\")
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = apply(:_c_any)
            unless _tmp
              self.pos = _save4
              break
            end
            while true
              _tmp = apply(:_sstring_norm)
              break unless _tmp
            end
            _tmp = true
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_SSTRING_BODY,  text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_SSTRING_BODY unless _tmp
    return _tmp
  end

  # t_SSTRING_BEGIN = < "'" > {token(:t_SSTRING_BEGIN, text)}
  def _t_SSTRING_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("'")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_SSTRING_BEGIN, text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_SSTRING_BEGIN unless _tmp
    return _tmp
  end

  # t_SSTRING_END = < "'" > {token(:t_SSTRING_END,   text)}
  def _t_SSTRING_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("'")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_SSTRING_END,   text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_SSTRING_END unless _tmp
    return _tmp
  end

  # catgry_norm = /[^\\\[\]]/
  def _catgry_norm
    _tmp = scan(/\A(?-mix:[^\\\[\]])/)
    set_failed_rule :_catgry_norm unless _tmp
    return _tmp
  end

  # t_CATGRY_BODY = < catgry_norm* ("\\" c_any catgry_norm*)* > {token(:t_CATGRY_BODY,   text)}
  def _t_CATGRY_BODY

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_catgry_norm)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        while true

          _save4 = self.pos
          while true # sequence
            _tmp = match_string("\\")
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = apply(:_c_any)
            unless _tmp
              self.pos = _save4
              break
            end
            while true
              _tmp = apply(:_catgry_norm)
              break unless _tmp
            end
            _tmp = true
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_CATGRY_BODY,   text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_CATGRY_BODY unless _tmp
    return _tmp
  end

  # t_CATGRY_BEGIN = < "[" > {token(:t_CATGRY_BEGIN,  text)}
  def _t_CATGRY_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("[")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_CATGRY_BEGIN,  text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_CATGRY_BEGIN unless _tmp
    return _tmp
  end

  # t_CATGRY_END = < "]" > {token(:t_CATGRY_END,    text)}
  def _t_CATGRY_END

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = match_string("]")
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_CATGRY_END,    text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_CATGRY_END unless _tmp
    return _tmp
  end

  # lit_simple = (t_NULL:t0 {node(:null,  t0)} | t_VOID:t0 {node(:void,  t0)} | t_TRUE:t0 {node(:true,  t0)} | t_FALSE:t0 {node(:false, t0)} | t_SELF:t0 {node(:self,  t0)} | t_FLOAT:t0 {node(:lit,   t0, t0.float)} | t_INTEGER:t0 {node(:lit,   t0, t0.integer)} | t_SYMBOL:t0 {node(:lit,   t0, t0.sym)})
  def _lit_simple

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_t_NULL)
        t0 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:null,  t0); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_t_VOID)
        t0 = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:void,  t0); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply(:_t_TRUE)
        t0 = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; node(:true,  t0); end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save4 = self.pos
      while true # sequence
        _tmp = apply(:_t_FALSE)
        t0 = @result
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin; node(:false, t0); end
        _tmp = true
        unless _tmp
          self.pos = _save4
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save5 = self.pos
      while true # sequence
        _tmp = apply(:_t_SELF)
        t0 = @result
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin; node(:self,  t0); end
        _tmp = true
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save6 = self.pos
      while true # sequence
        _tmp = apply(:_t_FLOAT)
        t0 = @result
        unless _tmp
          self.pos = _save6
          break
        end
        @result = begin; node(:lit,   t0, t0.float); end
        _tmp = true
        unless _tmp
          self.pos = _save6
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save7 = self.pos
      while true # sequence
        _tmp = apply(:_t_INTEGER)
        t0 = @result
        unless _tmp
          self.pos = _save7
          break
        end
        @result = begin; node(:lit,   t0, t0.integer); end
        _tmp = true
        unless _tmp
          self.pos = _save7
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save8 = self.pos
      while true # sequence
        _tmp = apply(:_t_SYMBOL)
        t0 = @result
        unless _tmp
          self.pos = _save8
          break
        end
        @result = begin; node(:lit,   t0, t0.sym); end
        _tmp = true
        unless _tmp
          self.pos = _save8
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_lit_simple unless _tmp
    return _tmp
  end

  # lit_string = (t_STRING_BEGIN t_STRING_BODY:tb t_STRING_END {node(:lit, tb, encode_escapes(tb.text))} | t_SSTRING_BEGIN t_SSTRING_BODY:tb t_SSTRING_END {node(:lit, tb, encode_escapes(tb.text))})
  def _lit_string

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_t_STRING_BEGIN)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_STRING_BODY)
        tb = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_STRING_END)
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:lit, tb, encode_escapes(tb.text)); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_t_SSTRING_BEGIN)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_SSTRING_BODY)
        tb = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_SSTRING_END)
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:lit, tb, encode_escapes(tb.text)); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_lit_string unless _tmp
    return _tmp
  end

  # lit_string_as_symbol = (t_STRING_BEGIN t_STRING_BODY:tb t_STRING_END {node(:lit, tb, encode_escapes(tb.text).to_sym)} | t_SSTRING_BEGIN t_SSTRING_BODY:tb t_SSTRING_END {node(:lit, tb, encode_escapes(tb.text).to_sym)})
  def _lit_string_as_symbol

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_t_STRING_BEGIN)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_STRING_BODY)
        tb = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_STRING_END)
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:lit, tb, encode_escapes(tb.text).to_sym); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_t_SSTRING_BEGIN)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_SSTRING_BODY)
        tb = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_SSTRING_END)
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:lit, tb, encode_escapes(tb.text).to_sym); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_lit_string_as_symbol unless _tmp
    return _tmp
  end

  # lit_symstr = t_SYMSTR_BEGIN t_STRING_BODY:tb t_STRING_END {node(:lit, tb, encode_escapes(tb.text).to_sym)}
  def _lit_symstr

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_SYMSTR_BEGIN)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_STRING_BODY)
      tb = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_STRING_END)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:lit, tb, encode_escapes(tb.text).to_sym); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_lit_symstr unless _tmp
    return _tmp
  end

  # category_name = t_CATGRY_BEGIN t_CATGRY_BODY:tb t_CATGRY_END {node(:lit, tb, encode_escapes(tb.text).to_sym)}
  def _category_name

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_CATGRY_BEGIN)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_CATGRY_BODY)
      tb = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_CATGRY_END)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:lit, tb, encode_escapes(tb.text).to_sym); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_category_name unless _tmp
    return _tmp
  end

  # dyn_string_parts = (c_spc* expr_atom_not_string:n0 c_spc* lit_string:n1 {[n0,n1]})+:nlist { nlist.flatten }
  def _dyn_string_parts

    _save = self.pos
    while true # sequence
      _save1 = self.pos
      _ary = []

      _save2 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_expr_atom_not_string)
        n0 = @result
        unless _tmp
          self.pos = _save2
          break
        end
        while true
          _tmp = apply(:_c_spc)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_lit_string)
        n1 = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; [n0,n1]; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        _ary << @result
        while true

          _save5 = self.pos
          while true # sequence
            while true
              _tmp = apply(:_c_spc)
              break unless _tmp
            end
            _tmp = true
            unless _tmp
              self.pos = _save5
              break
            end
            _tmp = apply(:_expr_atom_not_string)
            n0 = @result
            unless _tmp
              self.pos = _save5
              break
            end
            while true
              _tmp = apply(:_c_spc)
              break unless _tmp
            end
            _tmp = true
            unless _tmp
              self.pos = _save5
              break
            end
            _tmp = apply(:_lit_string)
            n1 = @result
            unless _tmp
              self.pos = _save5
              break
            end
            @result = begin; [n0,n1]; end
            _tmp = true
            unless _tmp
              self.pos = _save5
            end
            break
          end # end sequence

          _ary << @result if _tmp
          break unless _tmp
        end
        _tmp = true
        @result = _ary
      else
        self.pos = _save1
      end
      nlist = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  nlist.flatten ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_dyn_string_parts unless _tmp
    return _tmp
  end

  # dyn_string = lit_string:n0 dyn_string_parts:nrest {node(:dstr, n0, [n0] + nrest)}
  def _dyn_string

    _save = self.pos
    while true # sequence
      _tmp = apply(:_lit_string)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_dyn_string_parts)
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:dstr, n0, [n0] + nrest); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_dyn_string unless _tmp
    return _tmp
  end

  # dyn_symstr = lit_symstr:n0 dyn_string_parts:nrest {node(:dsym, n0, [n0] + nrest)}
  def _dyn_symstr

    _save = self.pos
    while true # sequence
      _tmp = apply(:_lit_symstr)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_dyn_string_parts)
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:dsym, n0, [n0] + nrest); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_dyn_symstr unless _tmp
    return _tmp
  end

  # constant = (constant:n0 t_SCOPE:ts t_CONSTANT:tc {node(:colon2, ts, n0, tc.sym)} | t_SCOPE:ts t_CONSTANT:tc {node(:colon3, ts, tc.sym)} | t_CONSTANT:tc {node(:const,  tc, tc.sym)})
  def _constant

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_constant)
        n0 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_SCOPE)
        ts = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_CONSTANT)
        tc = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:colon2, ts, n0, tc.sym); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_t_SCOPE)
        ts = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_CONSTANT)
        tc = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:colon3, ts, tc.sym); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply(:_t_CONSTANT)
        tc = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; node(:const,  tc, tc.sym); end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_constant unless _tmp
    return _tmp
  end

  # const_sep = (c_spc_nl* t_CONST_SEP c_spc_nl*)+
  def _const_sep
    _save = self.pos

    _save1 = self.pos
    while true # sequence
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save1
        break
      end
      _tmp = apply(:_t_CONST_SEP)
      unless _tmp
        self.pos = _save1
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save1
      end
      break
    end # end sequence

    if _tmp
      while true

        _save4 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_c_spc_nl)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
            break
          end
          _tmp = apply(:_t_CONST_SEP)
          unless _tmp
            self.pos = _save4
            break
          end
          while true
            _tmp = apply(:_c_spc_nl)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
          end
          break
        end # end sequence

        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save
    end
    set_failed_rule :_const_sep unless _tmp
    return _tmp
  end

  # constant_list = constant:n0 (const_sep constant:n)*:nrest {node(:arrass, n0, [n0, *nrest])}
  def _constant_list

    _save = self.pos
    while true # sequence
      _tmp = apply(:_constant)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply(:_const_sep)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_constant)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:arrass, n0, [n0, *nrest]); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_constant_list unless _tmp
    return _tmp
  end

  # id_as_symbol = t_IDENTIFIER:t0 {node(:lit, t0, t0.sym)}
  def _id_as_symbol

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_IDENTIFIER)
      t0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:lit, t0, t0.sym); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_id_as_symbol unless _tmp
    return _tmp
  end

  # declobj_sepd_exprs = declobj_expr:n0 (arg_sep declobj_expr:n)*:nrest arg_sep_opt { [n0, *nrest] }
  def _declobj_sepd_exprs

    _save = self.pos
    while true # sequence
      _tmp = apply(:_declobj_expr)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply(:_arg_sep)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_declobj_expr)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_arg_sep_opt)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [n0, *nrest] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_declobj_sepd_exprs unless _tmp
    return _tmp
  end

  # declobj_expr_body = (arg_sep_opt declobj_sepd_exprs:nlist t_DECLARE_END:te {node(:block, nlist.first, nlist)} | arg_sep_opt t_DECLARE_END:te {node(:null, te)})
  def _declobj_expr_body

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_declobj_sepd_exprs)
        nlist = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_DECLARE_END)
        te = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:block, nlist.first, nlist); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_DECLARE_END)
        te = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:null, te); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_declobj_expr_body unless _tmp
    return _tmp
  end

  # declobj = constant_list:n0 c_spc_nl* t_DECLARE_BEGIN:t declobj_expr_body:n1 {node(:declobj, t, n0, n1)}
  def _declobj

    _save = self.pos
    while true # sequence
      _tmp = apply(:_constant_list)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_DECLARE_BEGIN)
      t = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_declobj_expr_body)
      n1 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:declobj, t, n0, n1); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_declobj unless _tmp
    return _tmp
  end

  # category_expr = declobj_expr_not_category
  def _category_expr
    _tmp = apply(:_declobj_expr_not_category)
    set_failed_rule :_category_expr unless _tmp
    return _tmp
  end

  # category_sepd_exprs = arg_sep category_expr:n0 (arg_sep category_expr:n)*:nrest { [n0, *nrest] }
  def _category_sepd_exprs

    _save = self.pos
    while true # sequence
      _tmp = apply(:_arg_sep)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_category_expr)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply(:_arg_sep)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_category_expr)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [n0, *nrest] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_category_sepd_exprs unless _tmp
    return _tmp
  end

  # category = category_name:n0 category_sepd_exprs?:nlist &(arg_sep_opt (t_CATGRY_BEGIN | t_DECLARE_END)) {node(:category, n0, n0.value,       (nlist ? node(:block, nlist.first, nlist) : node(:null, n0)))}
  def _category

    _save = self.pos
    while true # sequence
      _tmp = apply(:_category_name)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = apply(:_category_sepd_exprs)
      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      nlist = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save2 = self.pos

      _save3 = self.pos
      while true # sequence
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save3
          break
        end

        _save4 = self.pos
        while true # choice
          _tmp = apply(:_t_CATGRY_BEGIN)
          break if _tmp
          self.pos = _save4
          _tmp = apply(:_t_DECLARE_END)
          break if _tmp
          self.pos = _save4
          break
        end # end choice

        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      self.pos = _save2
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:category, n0, n0.value,
      (nlist ? node(:block, nlist.first, nlist) : node(:null, n0))); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_category unless _tmp
    return _tmp
  end

  # copen = constant:n0 c_spc_nl* t_REOPEN:tb c_spc_nl* t_DECLARE_BEGIN declobj_expr_body:n1 {node(:copen, tb, n0, n1)}
  def _copen

    _save = self.pos
    while true # sequence
      _tmp = apply(:_constant)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_REOPEN)
      tb = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_DECLARE_BEGIN)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_declobj_expr_body)
      n1 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:copen, tb, n0, n1); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_copen unless _tmp
    return _tmp
  end

  # cdefn = constant:n0 c_spc_nl* t_DEFINE:t c_spc_nl* declobj:n1 {node(:cdefn, t, n0, n1)}
  def _cdefn

    _save = self.pos
    while true # sequence
      _tmp = apply(:_constant)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_DEFINE)
      t = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_declobj)
      n1 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:cdefn, t, n0, n1); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_cdefn unless _tmp
    return _tmp
  end

  # t_DECLSTR_BEGIN = < /[^\s{:,<][^\s]+/ > {      # Table of replacement characters to use when calculating   # the ending delimiter from the starting delimiter.   # Directional characters are replaced with their opposite.   @declstr_replace_tbl ||= %w{     < > ( ) { } [ ]   }      # Calculate the ending delimiter to look for and store it   @declstr_destrlim = text \     .split(/(?<=[^a-zA-Z])|(?=[^a-zA-Z])/)     .map { |str|       idx = @declstr_replace_tbl.find_index(str)       idx.nil? ? str :          (idx.odd? ? @declstr_replace_tbl[idx-1] : @declstr_replace_tbl[idx+1])     }     .reverse     .join ''      token(:t_DECLSTR_BEGIN, text) }
  def _t_DECLSTR_BEGIN

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?-mix:[^\s{:,<][^\s]+)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
  
  # Table of replacement characters to use when calculating
  # the ending delimiter from the starting delimiter.
  # Directional characters are replaced with their opposite.
  @declstr_replace_tbl ||= %w{
    < > ( ) { } [ ]
  }
  
  # Calculate the ending delimiter to look for and store it
  @declstr_destrlim = text \
    .split(/(?<=[^a-zA-Z])|(?=[^a-zA-Z])/)
    .map { |str|
      idx = @declstr_replace_tbl.find_index(str)
      idx.nil? ? str : 
        (idx.odd? ? @declstr_replace_tbl[idx-1] : @declstr_replace_tbl[idx+1])
    }
    .reverse
    .join ''
  
  token(:t_DECLSTR_BEGIN, text)
; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_DECLSTR_BEGIN unless _tmp
    return _tmp
  end

  # t_DECLSTR_END = c_spc_nl* < < /\S+/ > &{text == @declstr_destrlim} > {token(:t_DECLSTR_END, text)}
  def _t_DECLSTR_END

    _save = self.pos
    while true # sequence
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos

      _save2 = self.pos
      while true # sequence
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:\S+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save2
          break
        end
        _save3 = self.pos
        _tmp = begin; text == @declstr_destrlim; end
        self.pos = _save3
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; token(:t_DECLSTR_END, text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_DECLSTR_END unless _tmp
    return _tmp
  end

  # s_DECLSTR_BODYLINE = < /[^\n]*\n/ > &{ text =~ /^(\s*)(\S+)/; $2!=@declstr_destrlim } { text }
  def _s_DECLSTR_BODYLINE

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?-mix:[^\n]*\n)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = begin;  text =~ /^(\s*)(\S+)/; $2!=@declstr_destrlim ; end
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_s_DECLSTR_BODYLINE unless _tmp
    return _tmp
  end

  # s_DECLSTR_BODY = s_DECLSTR_BODYLINE*:slist { slist[1..-1].join('') }
  def _s_DECLSTR_BODY

    _save = self.pos
    while true # sequence
      _ary = []
      while true
        _tmp = apply(:_s_DECLSTR_BODYLINE)
        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      slist = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  slist[1..-1].join('') ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_s_DECLSTR_BODY unless _tmp
    return _tmp
  end

  # declstr_body = t_DECLSTR_BEGIN:tb s_DECLSTR_BODY:st c_spc_nl* t_DECLSTR_END {node(:str, tb, st)}
  def _declstr_body

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_DECLSTR_BEGIN)
      tb = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_s_DECLSTR_BODY)
      st = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_DECLSTR_END)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:str, tb, st); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_declstr_body unless _tmp
    return _tmp
  end

  # declstr = constant_list:nc c_spc+ declstr_body:nb {node(:declstr, nc, nc, nb)}
  def _declstr

    _save = self.pos
    while true # sequence
      _tmp = apply(:_constant_list)
      nc = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = apply(:_c_spc)
      if _tmp
        while true
          _tmp = apply(:_c_spc)
          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_declstr_body)
      nb = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:declstr, nc, nc, nb); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_declstr unless _tmp
    return _tmp
  end

  # assignment = (local_assignment | invoke_assignment)
  def _assignment

    _save = self.pos
    while true # choice
      _tmp = apply(:_local_assignment)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_invoke_assignment)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_assignment unless _tmp
    return _tmp
  end

  # assign_rhs = arg_expr
  def _assign_rhs
    _tmp = apply(:_arg_expr)
    set_failed_rule :_assign_rhs unless _tmp
    return _tmp
  end

  # local_assignment = t_IDENTIFIER:ti c_spc_nl* t_ASSIGN:to c_spc_nl* assign_rhs:rhs {node(:lasgn, to, ti.sym, rhs)}
  def _local_assignment

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_IDENTIFIER)
      ti = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_ASSIGN)
      to = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_assign_rhs)
      rhs = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:lasgn, to, ti.sym, rhs); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_local_assignment unless _tmp
    return _tmp
  end

  # invoke_assignment_lhs = (left_chained_invocations | invoke)
  def _invoke_assignment_lhs

    _save = self.pos
    while true # choice
      _tmp = apply(:_left_chained_invocations)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_invoke)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_invoke_assignment_lhs unless _tmp
    return _tmp
  end

  # invoke_assignment = invoke_assignment_lhs:lhs c_spc_nl* t_ASSIGN:to c_spc_nl* assign_rhs:rhs {   lhs.name = :"#{lhs.name}="   orig_arguments = lhs.arguments && lhs.arguments.body || []   arg_order = lhs.name==:"[]=" ? [*orig_arguments, rhs] : [rhs, *orig_arguments]   lhs.arguments = node(:argass, rhs, arg_order)   lhs }
  def _invoke_assignment

    _save = self.pos
    while true # sequence
      _tmp = apply(:_invoke_assignment_lhs)
      lhs = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_ASSIGN)
      to = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_assign_rhs)
      rhs = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
  lhs.name = :"#{lhs.name}="
  orig_arguments = lhs.arguments && lhs.arguments.body || []
  arg_order = lhs.name==:"[]=" ? [*orig_arguments, rhs] : [rhs, *orig_arguments]
  lhs.arguments = node(:argass, rhs, arg_order)
  lhs
; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_invoke_assignment unless _tmp
    return _tmp
  end

  # invoke_body = (c_spc_nl* param_list:n)?:np c_spc_nl* meme_enclosed_expr_body:nb { [np, nb] }
  def _invoke_body

    _save = self.pos
    while true # sequence
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_param_list)
        n = @result
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      np = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_meme_enclosed_expr_body)
      nb = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [np, nb] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_invoke_body unless _tmp
    return _tmp
  end

  # invoke = t_IDENTIFIER:tn (c_spc* arg_list:na)?:na (c_spc_nl* invoke_body:n)?:nlist {node(:invoke, tn, nil, tn.sym, na, *nlist)}
  def _invoke

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_IDENTIFIER)
      tn = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_arg_list)
        na = @result
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      na = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save4 = self.pos

      _save5 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply(:_invoke_body)
        n = @result
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save4
      end
      nlist = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:invoke, tn, nil, tn.sym, na, *nlist); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_invoke unless _tmp
    return _tmp
  end

  # op_invoke_id = left_op_normal
  def _op_invoke_id
    _tmp = apply(:_left_op_normal)
    set_failed_rule :_op_invoke_id unless _tmp
    return _tmp
  end

  # op_invoke = op_invoke_id:tn (c_spc* arg_list:na)?:na (c_spc_nl* invoke_body:n)?:nlist {node(:invoke, tn, nil, tn.sym, na, *nlist)}
  def _op_invoke

    _save = self.pos
    while true # sequence
      _tmp = apply(:_op_invoke_id)
      tn = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_arg_list)
        na = @result
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      na = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save4 = self.pos

      _save5 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply(:_invoke_body)
        n = @result
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save4
      end
      nlist = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:invoke, tn, nil, tn.sym, na, *nlist); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_op_invoke unless _tmp
    return _tmp
  end

  # elem_invoke = lit_array:na (c_spc_nl* invoke_body:n)?:nlist {node(:invoke, na, nil, :"[]", node(:argass, na, na.body), *nlist)}
  def _elem_invoke

    _save = self.pos
    while true # sequence
      _tmp = apply(:_lit_array)
      na = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_invoke_body)
        n = @result
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      nlist = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:invoke, na, nil, :"[]", node(:argass, na, na.body), *nlist); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_elem_invoke unless _tmp
    return _tmp
  end

  # arg_sep = (c_spc* t_ARG_SEP c_spc*)+
  def _arg_sep
    _save = self.pos

    _save1 = self.pos
    while true # sequence
      while true
        _tmp = apply(:_c_spc)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save1
        break
      end
      _tmp = apply(:_t_ARG_SEP)
      unless _tmp
        self.pos = _save1
        break
      end
      while true
        _tmp = apply(:_c_spc)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save1
      end
      break
    end # end sequence

    if _tmp
      while true

        _save4 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_c_spc)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
            break
          end
          _tmp = apply(:_t_ARG_SEP)
          unless _tmp
            self.pos = _save4
            break
          end
          while true
            _tmp = apply(:_c_spc)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
          end
          break
        end # end sequence

        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save
    end
    set_failed_rule :_arg_sep unless _tmp
    return _tmp
  end

  # arg_sep_opt = (c_spc | t_ARG_SEP)*
  def _arg_sep_opt
    while true

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_c_spc)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_t_ARG_SEP)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_arg_sep_opt unless _tmp
    return _tmp
  end

  # in_arg_normal = (in_arg_splat | arg_expr:n0 !in_arg_kwarg_mark { n0 })
  def _in_arg_normal

    _save = self.pos
    while true # choice
      _tmp = apply(:_in_arg_splat)
      break if _tmp
      self.pos = _save

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_arg_expr)
        n0 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _save2 = self.pos
        _tmp = apply(:_in_arg_kwarg_mark)
        _tmp = _tmp ? nil : true
        self.pos = _save2
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  n0 ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_in_arg_normal unless _tmp
    return _tmp
  end

  # in_arg_normals = in_arg_normal:n0 (arg_sep in_arg_normal:n)*:nrest { [n0,*nrest] }
  def _in_arg_normals

    _save = self.pos
    while true # sequence
      _tmp = apply(:_in_arg_normal)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply(:_arg_sep)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_in_arg_normal)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [n0,*nrest] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_in_arg_normals unless _tmp
    return _tmp
  end

  # in_arg_kwargs = in_arg_kwarg:n0 (arg_sep in_arg_kwarg:n)*:nrest {node(:hash, n0.first, [n0,*nrest].flatten)}
  def _in_arg_kwargs

    _save = self.pos
    while true # sequence
      _tmp = apply(:_in_arg_kwarg)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply(:_arg_sep)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_in_arg_kwarg)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:hash, n0.first, [n0,*nrest].flatten); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_in_arg_kwargs unless _tmp
    return _tmp
  end

  # in_arg_kwarg_mark = c_spc_nl* t_MEME_MARK:to
  def _in_arg_kwarg_mark

    _save = self.pos
    while true # sequence
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_MEME_MARK)
      to = @result
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_in_arg_kwarg_mark unless _tmp
    return _tmp
  end

  # in_arg_kwarg = id_as_symbol:n0 in_arg_kwarg_mark c_spc_nl* arg_expr:n1 { [n0, n1] }
  def _in_arg_kwarg

    _save = self.pos
    while true # sequence
      _tmp = apply(:_id_as_symbol)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_in_arg_kwarg_mark)
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_arg_expr)
      n1 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [n0, n1] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_in_arg_kwarg unless _tmp
    return _tmp
  end

  # in_arg_splat = t_OP_MULT:to expr_atom:n0 {node(:splat, to, n0)}
  def _in_arg_splat

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_OP_MULT)
      to = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_expr_atom)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:splat, to, n0); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_in_arg_splat unless _tmp
    return _tmp
  end

  # in_arg_block = t_OP_TOPROC:to expr_atom:n0 {node(:blkarg, to, n0)}
  def _in_arg_block

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_OP_TOPROC)
      to = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_expr_atom)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:blkarg, to, n0); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_in_arg_block unless _tmp
    return _tmp
  end

  # in_arg_list = (in_arg_normals:n0 arg_sep in_arg_kwargs:n1 arg_sep in_arg_block:n2 { [*n0,n1,n2] } | in_arg_normals:n0 arg_sep in_arg_kwargs:n1 { [*n0,n1] } | in_arg_normals:n0 arg_sep in_arg_block:n1 { [*n0,n1] } | in_arg_kwargs:n0 arg_sep in_arg_block:n1 { [n0, n1] } | in_arg_normals:n0 { [*n0] } | in_arg_kwargs:n0 { [n0] } | in_arg_block:n0 { [n0] })
  def _in_arg_list

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_in_arg_normals)
        n0 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_arg_sep)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_in_arg_kwargs)
        n1 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_arg_sep)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_in_arg_block)
        n2 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  [*n0,n1,n2] ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_in_arg_normals)
        n0 = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_arg_sep)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_in_arg_kwargs)
        n1 = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  [*n0,n1] ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply(:_in_arg_normals)
        n0 = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:_arg_sep)
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:_in_arg_block)
        n1 = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin;  [*n0,n1] ; end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save4 = self.pos
      while true # sequence
        _tmp = apply(:_in_arg_kwargs)
        n0 = @result
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = apply(:_arg_sep)
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = apply(:_in_arg_block)
        n1 = @result
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin;  [n0, n1] ; end
        _tmp = true
        unless _tmp
          self.pos = _save4
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save5 = self.pos
      while true # sequence
        _tmp = apply(:_in_arg_normals)
        n0 = @result
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin;  [*n0] ; end
        _tmp = true
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save6 = self.pos
      while true # sequence
        _tmp = apply(:_in_arg_kwargs)
        n0 = @result
        unless _tmp
          self.pos = _save6
          break
        end
        @result = begin;  [n0] ; end
        _tmp = true
        unless _tmp
          self.pos = _save6
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save7 = self.pos
      while true # sequence
        _tmp = apply(:_in_arg_block)
        n0 = @result
        unless _tmp
          self.pos = _save7
          break
        end
        @result = begin;  [n0] ; end
        _tmp = true
        unless _tmp
          self.pos = _save7
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_in_arg_list unless _tmp
    return _tmp
  end

  # arg_list = (t_ARGS_BEGIN:tb arg_sep_opt t_ARGS_END {node(:argass, tb, [])} | t_ARGS_BEGIN:tb arg_sep_opt in_arg_list:nlist arg_sep_opt t_ARGS_END {node(:argass, tb, nlist)})
  def _arg_list

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_t_ARGS_BEGIN)
        tb = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_ARGS_END)
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:argass, tb, []); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_t_ARGS_BEGIN)
        tb = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_in_arg_list)
        nlist = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_ARGS_END)
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:argass, tb, nlist); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_arg_list unless _tmp
    return _tmp
  end

  # lit_array = (t_ARRAY_BEGIN:tb arg_sep_opt t_ARRAY_END {node(:arrass, tb, [])} | t_ARRAY_BEGIN:tb arg_sep_opt in_arg_list:nlist arg_sep_opt t_ARRAY_END {node(:arrass, tb, nlist)})
  def _lit_array

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_t_ARRAY_BEGIN)
        tb = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_ARRAY_END)
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:arrass, tb, []); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_t_ARRAY_BEGIN)
        tb = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_in_arg_list)
        nlist = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_arg_sep_opt)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_ARRAY_END)
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:arrass, tb, nlist); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_lit_array unless _tmp
    return _tmp
  end

  # param = (t_IDENTIFIER:ti c_spc_nl* t_ASSIGN:to c_spc_nl* arg_expr:nv { [:optional, node(:lasgn, ti, ti.sym, nv)] } | t_IDENTIFIER:ti c_spc_nl* t_MEME_MARK:to c_spc_nl* arg_expr?:nv { [:kwargs, node(:lasgn, ti, ti.sym, (nv || node(:lit, to, :*)))] } | t_OP_EXP c_spc_nl* t_IDENTIFIER:ti { [:kwrest,   ti.sym] } | t_OP_MULT c_spc_nl* t_IDENTIFIER:ti { [:rest,     ti.sym] } | t_OP_TOPROC c_spc_nl* t_IDENTIFIER:ti { [:block,    ti.sym] } | t_IDENTIFIER:ti { [:required, ti.sym] })
  def _param

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_t_IDENTIFIER)
        ti = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_ASSIGN)
        to = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_arg_expr)
        nv = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  [:optional, node(:lasgn, ti, ti.sym, nv)] ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save4 = self.pos
      while true # sequence
        _tmp = apply(:_t_IDENTIFIER)
        ti = @result
        unless _tmp
          self.pos = _save4
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = apply(:_t_MEME_MARK)
        to = @result
        unless _tmp
          self.pos = _save4
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save4
          break
        end
        _save7 = self.pos
        _tmp = apply(:_arg_expr)
        @result = nil unless _tmp
        unless _tmp
          _tmp = true
          self.pos = _save7
        end
        nv = @result
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin;  [:kwargs, node(:lasgn, ti, ti.sym, (nv || node(:lit, to, :*)))] ; end
        _tmp = true
        unless _tmp
          self.pos = _save4
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save8 = self.pos
      while true # sequence
        _tmp = apply(:_t_OP_EXP)
        unless _tmp
          self.pos = _save8
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save8
          break
        end
        _tmp = apply(:_t_IDENTIFIER)
        ti = @result
        unless _tmp
          self.pos = _save8
          break
        end
        @result = begin;  [:kwrest,   ti.sym] ; end
        _tmp = true
        unless _tmp
          self.pos = _save8
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save10 = self.pos
      while true # sequence
        _tmp = apply(:_t_OP_MULT)
        unless _tmp
          self.pos = _save10
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save10
          break
        end
        _tmp = apply(:_t_IDENTIFIER)
        ti = @result
        unless _tmp
          self.pos = _save10
          break
        end
        @result = begin;  [:rest,     ti.sym] ; end
        _tmp = true
        unless _tmp
          self.pos = _save10
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save12 = self.pos
      while true # sequence
        _tmp = apply(:_t_OP_TOPROC)
        unless _tmp
          self.pos = _save12
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save12
          break
        end
        _tmp = apply(:_t_IDENTIFIER)
        ti = @result
        unless _tmp
          self.pos = _save12
          break
        end
        @result = begin;  [:block,    ti.sym] ; end
        _tmp = true
        unless _tmp
          self.pos = _save12
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save14 = self.pos
      while true # sequence
        _tmp = apply(:_t_IDENTIFIER)
        ti = @result
        unless _tmp
          self.pos = _save14
          break
        end
        @result = begin;  [:required, ti.sym] ; end
        _tmp = true
        unless _tmp
          self.pos = _save14
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_param unless _tmp
    return _tmp
  end

  # param_sepd = arg_sep param:n0 { n0 }
  def _param_sepd

    _save = self.pos
    while true # sequence
      _tmp = apply(:_arg_sep)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_param)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  n0 ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_param_sepd unless _tmp
    return _tmp
  end

  # param_sepds = param:n0 (arg_sep param:n)*:nrest arg_sep_opt { [n0, *nrest] }
  def _param_sepds

    _save = self.pos
    while true # sequence
      _tmp = apply(:_param)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply(:_arg_sep)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_param)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_arg_sep_opt)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [n0, *nrest] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_param_sepds unless _tmp
    return _tmp
  end

  # param_list = (t_PARAMS_BEGIN:tb t_PARAMS_END { node(:args, tb, [], [], nil, [], [], nil, nil) } | t_PARAMS_BEGIN:tb param_sepds:plist t_PARAMS_END {       required, optional, rest, post, kwargs, kwrest, block = 7.times.map { [] }              required << plist.shift[1] while plist[0] && plist[0][0] == :required       optional << plist.shift[1] while plist[0] && plist[0][0] == :optional       rest     << plist.shift[1] while plist[0] && plist[0][0] == :rest       post     << plist.shift[1] while plist[0] && plist[0][0] == :required       kwargs   << plist.shift[1] while plist[0] && plist[0][0] == :kwargs       kwrest   << plist.shift[1] while plist[0] && plist[0][0] == :kwrest       block    << plist.shift[1] while plist[0] && plist[0][0] == :block              required = required       optional = optional       rest     = rest.first       post     = post       kwargs   = kwargs       kwrest   = kwrest.first       block    = block.first              # TODO: move these conversions to their respective reductions       block = block && node(:blkprm, tb, block)              node(:args, tb, required, optional, rest, post, kwargs, kwrest, block)     })
  def _param_list

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_t_PARAMS_BEGIN)
        tb = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_PARAMS_END)
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  node(:args, tb, [], [], nil, [], [], nil, nil) ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_t_PARAMS_BEGIN)
        tb = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_param_sepds)
        plist = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_PARAMS_END)
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; 
      required, optional, rest, post, kwargs, kwrest, block = 7.times.map { [] }
      
      required << plist.shift[1] while plist[0] && plist[0][0] == :required
      optional << plist.shift[1] while plist[0] && plist[0][0] == :optional
      rest     << plist.shift[1] while plist[0] && plist[0][0] == :rest
      post     << plist.shift[1] while plist[0] && plist[0][0] == :required
      kwargs   << plist.shift[1] while plist[0] && plist[0][0] == :kwargs
      kwrest   << plist.shift[1] while plist[0] && plist[0][0] == :kwrest
      block    << plist.shift[1] while plist[0] && plist[0][0] == :block
      
      required = required
      optional = optional
      rest     = rest.first
      post     = post
      kwargs   = kwargs
      kwrest   = kwrest.first
      block    = block.first
      
      # TODO: move these conversions to their respective reductions
      block = block && node(:blkprm, tb, block)
      
      node(:args, tb, required, optional, rest, post, kwargs, kwrest, block)
    ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_param_list unless _tmp
    return _tmp
  end

  # left_op_normal = (t_OP_EXP | t_OP_MULT | t_OP_DIV | t_OP_MOD | t_OP_PLUS | t_OP_MINUS | t_OP_COMPARE)
  def _left_op_normal

    _save = self.pos
    while true # choice
      _tmp = apply(:_t_OP_EXP)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_MULT)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_DIV)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_MOD)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_PLUS)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_MINUS)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_COMPARE)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_left_op_normal unless _tmp
    return _tmp
  end

  # left_op_branch = (t_OP_AND | t_OP_OR | t_OP_AND_Q | t_OP_OR_Q | t_OP_VOID_Q)
  def _left_op_branch

    _save = self.pos
    while true # choice
      _tmp = apply(:_t_OP_AND)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_OR)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_AND_Q)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_OR_Q)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_OP_VOID_Q)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_left_op_branch unless _tmp
    return _tmp
  end

  # left_op = (left_op_normal | left_op_branch)
  def _left_op

    _save = self.pos
    while true # choice
      _tmp = apply(:_left_op_normal)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_left_op_branch)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_left_op unless _tmp
    return _tmp
  end

  # left_chained_atoms = expr_atom:n0 (c_spc_nl* left_op:to c_spc_nl* expr_atom:n1 { [to, n1] })+:list {   list.unshift n0   list.flatten!      collapse(list, :t_OP_EXP)   collapse(list, :t_OP_MULT, :t_OP_DIV, :t_OP_MOD)   collapse(list, :t_OP_PLUS, :t_OP_MINUS)   collapse(list, :t_OP_COMPARE)   collapse(list, :t_OP_AND, :t_OP_OR,                  :t_OP_AND_Q, :t_OP_OR_Q, :t_OP_VOID_Q) do |n0,op,n1|     node(:branch_op, op, op.sym, n0, n1)   end      # There should only be one resulting node left   raise "Failed to fully collapse left_chained_atoms: #{list}" \     unless list.count == 1      list.first }
  def _left_chained_atoms

    _save = self.pos
    while true # sequence
      _tmp = apply(:_expr_atom)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _ary = []

      _save2 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_left_op)
        to = @result
        unless _tmp
          self.pos = _save2
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_expr_atom)
        n1 = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  [to, n1] ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        _ary << @result
        while true

          _save5 = self.pos
          while true # sequence
            while true
              _tmp = apply(:_c_spc_nl)
              break unless _tmp
            end
            _tmp = true
            unless _tmp
              self.pos = _save5
              break
            end
            _tmp = apply(:_left_op)
            to = @result
            unless _tmp
              self.pos = _save5
              break
            end
            while true
              _tmp = apply(:_c_spc_nl)
              break unless _tmp
            end
            _tmp = true
            unless _tmp
              self.pos = _save5
              break
            end
            _tmp = apply(:_expr_atom)
            n1 = @result
            unless _tmp
              self.pos = _save5
              break
            end
            @result = begin;  [to, n1] ; end
            _tmp = true
            unless _tmp
              self.pos = _save5
            end
            break
          end # end sequence

          _ary << @result if _tmp
          break unless _tmp
        end
        _tmp = true
        @result = _ary
      else
        self.pos = _save1
      end
      list = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
  list.unshift n0
  list.flatten!
  
  collapse(list, :t_OP_EXP)
  collapse(list, :t_OP_MULT, :t_OP_DIV, :t_OP_MOD)
  collapse(list, :t_OP_PLUS, :t_OP_MINUS)
  collapse(list, :t_OP_COMPARE)
  collapse(list, :t_OP_AND, :t_OP_OR,
                 :t_OP_AND_Q, :t_OP_OR_Q, :t_OP_VOID_Q) do |n0,op,n1|
    node(:branch_op, op, op.sym, n0, n1)
  end
  
  # There should only be one resulting node left
  raise "Failed to fully collapse left_chained_atoms: #{list}" \
    unless list.count == 1
  
  list.first
; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_left_chained_atoms unless _tmp
    return _tmp
  end

  # left_invoke_op = (t_QUEST | t_DOT)
  def _left_invoke_op

    _save = self.pos
    while true # choice
      _tmp = apply(:_t_QUEST)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_t_DOT)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_left_invoke_op unless _tmp
    return _tmp
  end

  # left_chained_invocation = (c_spc_nl* left_invoke_op:to c_spc_nl* (invoke | op_invoke):n1 { [to, n1] } | c_spc* elem_invoke:n1 { [token(:t_DOT, ""), n1] })
  def _left_chained_invocation

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_left_invoke_op)
        to = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end

        _save4 = self.pos
        while true # choice
          _tmp = apply(:_invoke)
          break if _tmp
          self.pos = _save4
          _tmp = apply(:_op_invoke)
          break if _tmp
          self.pos = _save4
          break
        end # end choice

        n1 = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  [to, n1] ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save5 = self.pos
      while true # sequence
        while true
          _tmp = apply(:_c_spc)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply(:_elem_invoke)
        n1 = @result
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin;  [token(:t_DOT, ""), n1] ; end
        _tmp = true
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_left_chained_invocation unless _tmp
    return _tmp
  end

  # left_chained_invocations = expr_atom_not_chained:n0 left_chained_invocation+:list {   list.unshift n0   list.flatten!      collapse(list, :t_DOT, :t_QUEST) do |n0,op,n1|     op.type==:t_DOT ? (n1.receiver=n0; n1) : node(:quest, op, n0, n1)   end      # There should only be one resulting node left   raise "Failed to fully collapse left_chained_invocations: #{list}" \     unless list.count == 1      list.first }
  def _left_chained_invocations

    _save = self.pos
    while true # sequence
      _tmp = apply(:_expr_atom_not_chained)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _ary = []
      _tmp = apply(:_left_chained_invocation)
      if _tmp
        _ary << @result
        while true
          _tmp = apply(:_left_chained_invocation)
          _ary << @result if _tmp
          break unless _tmp
        end
        _tmp = true
        @result = _ary
      else
        self.pos = _save1
      end
      list = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
  list.unshift n0
  list.flatten!
  
  collapse(list, :t_DOT, :t_QUEST) do |n0,op,n1|
    op.type==:t_DOT ? (n1.receiver=n0; n1) : node(:quest, op, n0, n1)
  end
  
  # There should only be one resulting node left
  raise "Failed to fully collapse left_chained_invocations: #{list}" \
    unless list.count == 1
  
  list.first
; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_left_chained_invocations unless _tmp
    return _tmp
  end

  # unary_operation = t_OP_NOT:to expr_atom:n0 {node(:invoke, to, n0, :"!", nil)}
  def _unary_operation

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_OP_NOT)
      to = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_expr_atom)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:invoke, to, n0, :"!", nil); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_unary_operation unless _tmp
    return _tmp
  end

  # t_inln_sep = !t_ARG_SEP t_EXPR_SEP
  def _t_inln_sep

    _save = self.pos
    while true # sequence
      _save1 = self.pos
      _tmp = apply(:_t_ARG_SEP)
      _tmp = _tmp ? nil : true
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_EXPR_SEP)
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_t_inln_sep unless _tmp
    return _tmp
  end

  # inln_sep = (c_spc* t_inln_sep c_spc*)+
  def _inln_sep
    _save = self.pos

    _save1 = self.pos
    while true # sequence
      while true
        _tmp = apply(:_c_spc)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save1
        break
      end
      _tmp = apply(:_t_inln_sep)
      unless _tmp
        self.pos = _save1
        break
      end
      while true
        _tmp = apply(:_c_spc)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save1
      end
      break
    end # end sequence

    if _tmp
      while true

        _save4 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_c_spc)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
            break
          end
          _tmp = apply(:_t_inln_sep)
          unless _tmp
            self.pos = _save4
            break
          end
          while true
            _tmp = apply(:_c_spc)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
          end
          break
        end # end sequence

        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save
    end
    set_failed_rule :_inln_sep unless _tmp
    return _tmp
  end

  # inln_sep_opt = (c_spc | t_inln_sep)*
  def _inln_sep_opt
    while true

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_c_spc)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_t_inln_sep)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_inln_sep_opt unless _tmp
    return _tmp
  end

  # expr_sep = (c_spc* t_EXPR_SEP c_spc*)+
  def _expr_sep
    _save = self.pos

    _save1 = self.pos
    while true # sequence
      while true
        _tmp = apply(:_c_spc)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save1
        break
      end
      _tmp = apply(:_t_EXPR_SEP)
      unless _tmp
        self.pos = _save1
        break
      end
      while true
        _tmp = apply(:_c_spc)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save1
      end
      break
    end # end sequence

    if _tmp
      while true

        _save4 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_c_spc)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
            break
          end
          _tmp = apply(:_t_EXPR_SEP)
          unless _tmp
            self.pos = _save4
            break
          end
          while true
            _tmp = apply(:_c_spc)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
          end
          break
        end # end sequence

        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save
    end
    set_failed_rule :_expr_sep unless _tmp
    return _tmp
  end

  # expr_sep_opt = (c_spc | t_EXPR_SEP)*
  def _expr_sep_opt
    while true

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_c_spc)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_t_EXPR_SEP)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_expr_sep_opt unless _tmp
    return _tmp
  end

  # meme_inline_sepd_exprs = meme_expr:n0 (inln_sep meme_expr:n)*:nrest inln_sep_opt { [n0, *nrest] }
  def _meme_inline_sepd_exprs

    _save = self.pos
    while true # sequence
      _tmp = apply(:_meme_expr)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply(:_inln_sep)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_meme_expr)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_inln_sep_opt)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [n0, *nrest] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_meme_inline_sepd_exprs unless _tmp
    return _tmp
  end

  # meme_sepd_exprs = meme_expr:n0 (expr_sep meme_expr:n)*:nrest expr_sep_opt { [n0, *nrest] }
  def _meme_sepd_exprs

    _save = self.pos
    while true # sequence
      _tmp = apply(:_meme_expr)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply(:_expr_sep)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_meme_expr)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_expr_sep_opt)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  [n0, *nrest] ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_meme_sepd_exprs unless _tmp
    return _tmp
  end

  # meme_inline_expr_body = inln_sep_opt meme_inline_sepd_exprs:nlist {node(:block, nlist.first, nlist)}
  def _meme_inline_expr_body

    _save = self.pos
    while true # sequence
      _tmp = apply(:_inln_sep_opt)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_meme_inline_sepd_exprs)
      nlist = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:block, nlist.first, nlist); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_meme_inline_expr_body unless _tmp
    return _tmp
  end

  # meme_expr_body = (expr_sep_opt meme_sepd_exprs:nlist t_MEME_END:te {node(:block, nlist.first, nlist)} | expr_sep_opt t_MEME_END:te {node(:null, te)})
  def _meme_expr_body

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_expr_sep_opt)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_meme_sepd_exprs)
        nlist = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_MEME_END)
        te = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:block, nlist.first, nlist); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_expr_sep_opt)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_MEME_END)
        te = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:null, te); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_meme_expr_body unless _tmp
    return _tmp
  end

  # paren_expr_body = (expr_sep_opt meme_sepd_exprs:nlist t_PAREN_END:te { nlist.count==1 ? nlist.first : node(:block, nlist.first, nlist) } | expr_sep_opt t_PAREN_END:te {node(:null, te)})
  def _paren_expr_body

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_expr_sep_opt)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_meme_sepd_exprs)
        nlist = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_PAREN_END)
        te = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  nlist.count==1 ? nlist.first : node(:block, nlist.first, nlist) ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_expr_sep_opt)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_t_PAREN_END)
        te = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; node(:null, te); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_paren_expr_body unless _tmp
    return _tmp
  end

  # paren_expr = t_PAREN_BEGIN paren_expr_body:n0 { n0 }
  def _paren_expr

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_PAREN_BEGIN)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_paren_expr_body)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  n0 ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_paren_expr unless _tmp
    return _tmp
  end

  # meme_enclosed_expr_body = t_MEME_BEGIN meme_expr_body:n0 { n0 }
  def _meme_enclosed_expr_body

    _save = self.pos
    while true # sequence
      _tmp = apply(:_t_MEME_BEGIN)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_meme_expr_body)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  n0 ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_meme_enclosed_expr_body unless _tmp
    return _tmp
  end

  # meme_either_body = (meme_enclosed_expr_body | meme_inline_expr_body)
  def _meme_either_body

    _save = self.pos
    while true # choice
      _tmp = apply(:_meme_enclosed_expr_body)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_meme_inline_expr_body)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_meme_either_body unless _tmp
    return _tmp
  end

  # cmeme = constant:n0 c_spc* t_MEME_MARK:tm c_spc_nl* meme_inline_expr_body:n1 {node(:cdecl, tm, n0, n1)}
  def _cmeme

    _save = self.pos
    while true # sequence
      _tmp = apply(:_constant)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_t_MEME_MARK)
      tm = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_c_spc_nl)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_meme_inline_expr_body)
      n1 = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:cdecl, tm, n0, n1); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_cmeme unless _tmp
    return _tmp
  end

  # meme_name = (id_as_symbol | lit_string_as_symbol)
  def _meme_name

    _save = self.pos
    while true # choice
      _tmp = apply(:_id_as_symbol)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_lit_string_as_symbol)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_meme_name unless _tmp
    return _tmp
  end

  # decorator = meme_name:ni arg_list?:na {node(:deco, ni, ni, (na ? node(:arrass, na, na.body) : nil))}
  def _decorator

    _save = self.pos
    while true # sequence
      _tmp = apply(:_meme_name)
      ni = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = apply(:_arg_list)
      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      na = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:deco, ni, ni, (na ? node(:arrass, na, na.body) : nil)); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_decorator unless _tmp
    return _tmp
  end

  # decorators_and_meme_name = decorator:n0 (c_spc* decorator:n)*:nrest {node(:arrass, n0, [n0, *nrest].reverse)}
  def _decorators_and_meme_name

    _save = self.pos
    while true # sequence
      _tmp = apply(:_decorator)
      n0 = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_c_spc)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_decorator)
          n = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      nrest = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; node(:arrass, n0, [n0, *nrest].reverse); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_decorators_and_meme_name unless _tmp
    return _tmp
  end

  # meme = (decorators_and_meme_name:nd c_spc* t_MEME_MARK:tm (c_spc_nl* param_list:n)?:np c_spc_nl* meme_either_body:nb {node(:meme, tm, nd.body.shift.name, nd, np,  nb)} | decorators_and_meme_name:nd {node(:meme, tm, nd.body.shift.name, nd, nil, nil)})
  def _meme

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_decorators_and_meme_name)
        nd = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_spc)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t_MEME_MARK)
        tm = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos

        _save4 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_c_spc_nl)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save4
            break
          end
          _tmp = apply(:_param_list)
          n = @result
          unless _tmp
            self.pos = _save4
          end
          break
        end # end sequence

        @result = nil unless _tmp
        unless _tmp
          _tmp = true
          self.pos = _save3
        end
        np = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_c_spc_nl)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_meme_either_body)
        nb = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; node(:meme, tm, nd.body.shift.name, nd, np,  nb); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save7 = self.pos
      while true # sequence
        _tmp = apply(:_decorators_and_meme_name)
        nd = @result
        unless _tmp
          self.pos = _save7
          break
        end
        @result = begin; node(:meme, tm, nd.body.shift.name, nd, nil, nil); end
        _tmp = true
        unless _tmp
          self.pos = _save7
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_meme unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_root] = rule_info("root", "declobj_expr_body:n0 { @root_node = node(:declfile, n0, n0) }")
  Rules[:_decl] = rule_info("decl", "(declobj | declstr | copen)")
  Rules[:_declobj_expr] = rule_info("declobj_expr", "(category | declobj_expr_not_category)")
  Rules[:_declobj_expr_not_category] = rule_info("declobj_expr_not_category", "(decl | cdefn | cmeme | constant | meme)")
  Rules[:_meme_expr] = rule_info("meme_expr", "arg_expr")
  Rules[:_arg_expr] = rule_info("arg_expr", "(assignment | left_chained_atoms | dyn_string | dyn_symstr | expr_atom)")
  Rules[:_expr_atom] = rule_info("expr_atom", "(decl | left_chained_invocations | lit_string | lit_symstr | unary_operation | paren_expr | constant | lit_simple | lit_array | invoke)")
  Rules[:_expr_atom_not_chained] = rule_info("expr_atom_not_chained", "(decl | lit_string | lit_symstr | unary_operation | paren_expr | constant | lit_simple | lit_array | invoke)")
  Rules[:_expr_atom_not_string] = rule_info("expr_atom_not_string", "(decl | left_chained_invocations | unary_operation | paren_expr | constant | lit_simple | lit_array | invoke)")
  Rules[:_eol_comment] = rule_info("eol_comment", "\"\#\" (!c_eol .)*")
  Rules[:_c_nl] = rule_info("c_nl", "\"\\n\"")
  Rules[:_c_spc] = rule_info("c_spc", "(/[ \\t\\r\\f\\v]/ | \"\\\\\\n\" | eol_comment)")
  Rules[:_c_spc_nl] = rule_info("c_spc_nl", "(c_spc | c_nl)")
  Rules[:_c_eof] = rule_info("c_eof", "!.")
  Rules[:_c_eol] = rule_info("c_eol", "(c_nl | c_eof)")
  Rules[:_c_any] = rule_info("c_any", ".")
  Rules[:_c_upper] = rule_info("c_upper", "/[[:upper:]]/")
  Rules[:_c_lower] = rule_info("c_lower", "(/[[:lower:]]/ | \"_\")")
  Rules[:_c_num] = rule_info("c_num", "/[0-9]/")
  Rules[:_c_alpha] = rule_info("c_alpha", "(c_lower | c_upper)")
  Rules[:_c_alnum] = rule_info("c_alnum", "(c_alpha | c_num)")
  Rules[:_c_suffix] = rule_info("c_suffix", "(\"!\" | \"?\")")
  Rules[:_t_CONST_SEP] = rule_info("t_CONST_SEP", "< \",\" > {token(:t_CONST_SEP,     text)}")
  Rules[:_t_EXPR_SEP] = rule_info("t_EXPR_SEP", "< (\";\" | c_nl) > {token(:t_EXPR_SEP,      text)}")
  Rules[:_t_ARG_SEP] = rule_info("t_ARG_SEP", "< (\",\" | c_nl) > {token(:t_ARG_SEP,       text)}")
  Rules[:_t_DECLARE_BEGIN] = rule_info("t_DECLARE_BEGIN", "< \"{\" > {token(:t_DECLARE_BEGIN, text)}")
  Rules[:_t_DECLARE_END] = rule_info("t_DECLARE_END", "< (\"}\" | c_eof) > {token(:t_DECLARE_END,   text)}")
  Rules[:_t_MEME_MARK] = rule_info("t_MEME_MARK", "< \":\" > {token(:t_MEME_MARK,     text)}")
  Rules[:_t_MEME_BEGIN] = rule_info("t_MEME_BEGIN", "< \"{\" > {token(:t_MEME_BEGIN,    text)}")
  Rules[:_t_MEME_END] = rule_info("t_MEME_END", "< \"}\" > {token(:t_MEME_END,      text)}")
  Rules[:_t_PAREN_BEGIN] = rule_info("t_PAREN_BEGIN", "< \"(\" > {token(:t_PAREN_BEGIN,   text)}")
  Rules[:_t_PAREN_END] = rule_info("t_PAREN_END", "< \")\" > {token(:t_PAREN_END,     text)}")
  Rules[:_t_DEFINE] = rule_info("t_DEFINE", "< \"<\" > {token(:t_DEFINE,        text)}")
  Rules[:_t_REOPEN] = rule_info("t_REOPEN", "< \"<<\" > {token(:t_REOPEN,        text)}")
  Rules[:_t_PARAMS_BEGIN] = rule_info("t_PARAMS_BEGIN", "< \"|\" > {token(:t_PARAMS_BEGIN,  text)}")
  Rules[:_t_PARAMS_END] = rule_info("t_PARAMS_END", "< \"|\" > {token(:t_PARAMS_END,    text)}")
  Rules[:_t_ARGS_BEGIN] = rule_info("t_ARGS_BEGIN", "< \"(\" > {token(:t_ARGS_BEGIN,    text)}")
  Rules[:_t_ARGS_END] = rule_info("t_ARGS_END", "< \")\" > {token(:t_ARGS_END,      text)}")
  Rules[:_t_ARRAY_BEGIN] = rule_info("t_ARRAY_BEGIN", "< \"[\" > {token(:t_ARRAY_BEGIN,   text)}")
  Rules[:_t_ARRAY_END] = rule_info("t_ARRAY_END", "< \"]\" > {token(:t_ARRAY_END,     text)}")
  Rules[:_t_CONSTANT] = rule_info("t_CONSTANT", "< c_upper c_alnum* > {token(:t_CONSTANT,      text)}")
  Rules[:_t_IDENTIFIER] = rule_info("t_IDENTIFIER", "< c_lower c_alnum* c_suffix? > {token(:t_IDENTIFIER,    text)}")
  Rules[:_t_SYMBOL] = rule_info("t_SYMBOL", "\":\" < c_lower c_alnum* > {token(:t_SYMBOL,        text)}")
  Rules[:_t_NULL] = rule_info("t_NULL", "< \"null\" > {token(:t_NULL,          text)}")
  Rules[:_t_VOID] = rule_info("t_VOID", "< \"void\" > {token(:t_VOID,          text)}")
  Rules[:_t_TRUE] = rule_info("t_TRUE", "< \"true\" > {token(:t_TRUE,          text)}")
  Rules[:_t_FALSE] = rule_info("t_FALSE", "< \"false\" > {token(:t_FALSE,         text)}")
  Rules[:_t_SELF] = rule_info("t_SELF", "< \"self\" > {token(:t_SELF,          text)}")
  Rules[:_t_FLOAT] = rule_info("t_FLOAT", "< \"-\"? c_num+ \".\" c_num+ > {token(:t_FLOAT,         text)}")
  Rules[:_t_INTEGER] = rule_info("t_INTEGER", "< \"-\"? c_num+ > {token(:t_INTEGER,       text)}")
  Rules[:_t_DOT] = rule_info("t_DOT", "< \".\" > {token(:t_DOT,           text)}")
  Rules[:_t_QUEST] = rule_info("t_QUEST", "< \".\" c_spc_nl* \"?\" > {token(:t_QUEST,         text)}")
  Rules[:_t_SCOPE] = rule_info("t_SCOPE", "< \"::\" > {token(:t_SCOPE,         text)}")
  Rules[:_t_ASSIGN] = rule_info("t_ASSIGN", "< \"=\" > {token(:t_ASSIGN,        text)}")
  Rules[:_t_OP_TOPROC] = rule_info("t_OP_TOPROC", "< \"&\" > {token(:t_OP_TOPROC,     text)}")
  Rules[:_t_OP_NOT] = rule_info("t_OP_NOT", "< \"!\" > {token(:t_OP_NOT,        text)}")
  Rules[:_t_OP_PLUS] = rule_info("t_OP_PLUS", "< \"+\" > {token(:t_OP_PLUS,       text)}")
  Rules[:_t_OP_MINUS] = rule_info("t_OP_MINUS", "< \"-\" > {token(:t_OP_MINUS,      text)}")
  Rules[:_t_OP_MULT] = rule_info("t_OP_MULT", "< \"*\" > {token(:t_OP_MULT,       text)}")
  Rules[:_t_OP_DIV] = rule_info("t_OP_DIV", "< \"/\" > {token(:t_OP_DIV,        text)}")
  Rules[:_t_OP_MOD] = rule_info("t_OP_MOD", "< \"%\" > {token(:t_OP_MOD,        text)}")
  Rules[:_t_OP_EXP] = rule_info("t_OP_EXP", "< \"**\" > {token(:t_OP_EXP,        text)}")
  Rules[:_t_OP_AND] = rule_info("t_OP_AND", "< \"&&\" > {token(:t_OP_AND,        text)}")
  Rules[:_t_OP_OR] = rule_info("t_OP_OR", "< \"||\" > {token(:t_OP_OR,         text)}")
  Rules[:_t_OP_AND_Q] = rule_info("t_OP_AND_Q", "< \"&?\" > {token(:t_OP_AND_Q,      text)}")
  Rules[:_t_OP_OR_Q] = rule_info("t_OP_OR_Q", "< \"|?\" > {token(:t_OP_OR_Q,       text)}")
  Rules[:_t_OP_VOID_Q] = rule_info("t_OP_VOID_Q", "< \"??\" > {token(:t_OP_VOID_Q,     text)}")
  Rules[:_t_OP_COMPARE] = rule_info("t_OP_COMPARE", "< (\"<=>\" | \"=~\" | \"==\" | \"<=\" | \">=\" | \"<\" | \">\") > {token(:t_OP_COMPARE,    text)}")
  Rules[:_string_norm] = rule_info("string_norm", "/[^\\\\\\\"]/")
  Rules[:_t_STRING_BODY] = rule_info("t_STRING_BODY", "< string_norm* (\"\\\\\" c_any string_norm*)* > {token(:t_STRING_BODY,   text)}")
  Rules[:_t_STRING_BEGIN] = rule_info("t_STRING_BEGIN", "< \"\\\"\" > {token(:t_STRING_BEGIN,  text)}")
  Rules[:_t_STRING_END] = rule_info("t_STRING_END", "< \"\\\"\" > {token(:t_STRING_END,    text)}")
  Rules[:_t_SYMSTR_BEGIN] = rule_info("t_SYMSTR_BEGIN", "< \":\\\"\" > {token(:t_SYMSTR_BEGIN,  text)}")
  Rules[:_sstring_norm] = rule_info("sstring_norm", "/[^\\\\\\']/")
  Rules[:_t_SSTRING_BODY] = rule_info("t_SSTRING_BODY", "< sstring_norm* (\"\\\\\" c_any sstring_norm*)* > {token(:t_SSTRING_BODY,  text)}")
  Rules[:_t_SSTRING_BEGIN] = rule_info("t_SSTRING_BEGIN", "< \"'\" > {token(:t_SSTRING_BEGIN, text)}")
  Rules[:_t_SSTRING_END] = rule_info("t_SSTRING_END", "< \"'\" > {token(:t_SSTRING_END,   text)}")
  Rules[:_catgry_norm] = rule_info("catgry_norm", "/[^\\\\\\[\\]]/")
  Rules[:_t_CATGRY_BODY] = rule_info("t_CATGRY_BODY", "< catgry_norm* (\"\\\\\" c_any catgry_norm*)* > {token(:t_CATGRY_BODY,   text)}")
  Rules[:_t_CATGRY_BEGIN] = rule_info("t_CATGRY_BEGIN", "< \"[\" > {token(:t_CATGRY_BEGIN,  text)}")
  Rules[:_t_CATGRY_END] = rule_info("t_CATGRY_END", "< \"]\" > {token(:t_CATGRY_END,    text)}")
  Rules[:_lit_simple] = rule_info("lit_simple", "(t_NULL:t0 {node(:null,  t0)} | t_VOID:t0 {node(:void,  t0)} | t_TRUE:t0 {node(:true,  t0)} | t_FALSE:t0 {node(:false, t0)} | t_SELF:t0 {node(:self,  t0)} | t_FLOAT:t0 {node(:lit,   t0, t0.float)} | t_INTEGER:t0 {node(:lit,   t0, t0.integer)} | t_SYMBOL:t0 {node(:lit,   t0, t0.sym)})")
  Rules[:_lit_string] = rule_info("lit_string", "(t_STRING_BEGIN t_STRING_BODY:tb t_STRING_END {node(:lit, tb, encode_escapes(tb.text))} | t_SSTRING_BEGIN t_SSTRING_BODY:tb t_SSTRING_END {node(:lit, tb, encode_escapes(tb.text))})")
  Rules[:_lit_string_as_symbol] = rule_info("lit_string_as_symbol", "(t_STRING_BEGIN t_STRING_BODY:tb t_STRING_END {node(:lit, tb, encode_escapes(tb.text).to_sym)} | t_SSTRING_BEGIN t_SSTRING_BODY:tb t_SSTRING_END {node(:lit, tb, encode_escapes(tb.text).to_sym)})")
  Rules[:_lit_symstr] = rule_info("lit_symstr", "t_SYMSTR_BEGIN t_STRING_BODY:tb t_STRING_END {node(:lit, tb, encode_escapes(tb.text).to_sym)}")
  Rules[:_category_name] = rule_info("category_name", "t_CATGRY_BEGIN t_CATGRY_BODY:tb t_CATGRY_END {node(:lit, tb, encode_escapes(tb.text).to_sym)}")
  Rules[:_dyn_string_parts] = rule_info("dyn_string_parts", "(c_spc* expr_atom_not_string:n0 c_spc* lit_string:n1 {[n0,n1]})+:nlist { nlist.flatten }")
  Rules[:_dyn_string] = rule_info("dyn_string", "lit_string:n0 dyn_string_parts:nrest {node(:dstr, n0, [n0] + nrest)}")
  Rules[:_dyn_symstr] = rule_info("dyn_symstr", "lit_symstr:n0 dyn_string_parts:nrest {node(:dsym, n0, [n0] + nrest)}")
  Rules[:_constant] = rule_info("constant", "(constant:n0 t_SCOPE:ts t_CONSTANT:tc {node(:colon2, ts, n0, tc.sym)} | t_SCOPE:ts t_CONSTANT:tc {node(:colon3, ts, tc.sym)} | t_CONSTANT:tc {node(:const,  tc, tc.sym)})")
  Rules[:_const_sep] = rule_info("const_sep", "(c_spc_nl* t_CONST_SEP c_spc_nl*)+")
  Rules[:_constant_list] = rule_info("constant_list", "constant:n0 (const_sep constant:n)*:nrest {node(:arrass, n0, [n0, *nrest])}")
  Rules[:_id_as_symbol] = rule_info("id_as_symbol", "t_IDENTIFIER:t0 {node(:lit, t0, t0.sym)}")
  Rules[:_declobj_sepd_exprs] = rule_info("declobj_sepd_exprs", "declobj_expr:n0 (arg_sep declobj_expr:n)*:nrest arg_sep_opt { [n0, *nrest] }")
  Rules[:_declobj_expr_body] = rule_info("declobj_expr_body", "(arg_sep_opt declobj_sepd_exprs:nlist t_DECLARE_END:te {node(:block, nlist.first, nlist)} | arg_sep_opt t_DECLARE_END:te {node(:null, te)})")
  Rules[:_declobj] = rule_info("declobj", "constant_list:n0 c_spc_nl* t_DECLARE_BEGIN:t declobj_expr_body:n1 {node(:declobj, t, n0, n1)}")
  Rules[:_category_expr] = rule_info("category_expr", "declobj_expr_not_category")
  Rules[:_category_sepd_exprs] = rule_info("category_sepd_exprs", "arg_sep category_expr:n0 (arg_sep category_expr:n)*:nrest { [n0, *nrest] }")
  Rules[:_category] = rule_info("category", "category_name:n0 category_sepd_exprs?:nlist &(arg_sep_opt (t_CATGRY_BEGIN | t_DECLARE_END)) {node(:category, n0, n0.value,       (nlist ? node(:block, nlist.first, nlist) : node(:null, n0)))}")
  Rules[:_copen] = rule_info("copen", "constant:n0 c_spc_nl* t_REOPEN:tb c_spc_nl* t_DECLARE_BEGIN declobj_expr_body:n1 {node(:copen, tb, n0, n1)}")
  Rules[:_cdefn] = rule_info("cdefn", "constant:n0 c_spc_nl* t_DEFINE:t c_spc_nl* declobj:n1 {node(:cdefn, t, n0, n1)}")
  Rules[:_t_DECLSTR_BEGIN] = rule_info("t_DECLSTR_BEGIN", "< /[^\\s{:,<][^\\s]+/ > {      \# Table of replacement characters to use when calculating   \# the ending delimiter from the starting delimiter.   \# Directional characters are replaced with their opposite.   @declstr_replace_tbl ||= %w{     < > ( ) { } [ ]   }      \# Calculate the ending delimiter to look for and store it   @declstr_destrlim = text \\     .split(/(?<=[^a-zA-Z])|(?=[^a-zA-Z])/)     .map { |str|       idx = @declstr_replace_tbl.find_index(str)       idx.nil? ? str :          (idx.odd? ? @declstr_replace_tbl[idx-1] : @declstr_replace_tbl[idx+1])     }     .reverse     .join ''      token(:t_DECLSTR_BEGIN, text) }")
  Rules[:_t_DECLSTR_END] = rule_info("t_DECLSTR_END", "c_spc_nl* < < /\\S+/ > &{text == @declstr_destrlim} > {token(:t_DECLSTR_END, text)}")
  Rules[:_s_DECLSTR_BODYLINE] = rule_info("s_DECLSTR_BODYLINE", "< /[^\\n]*\\n/ > &{ text =~ /^(\\s*)(\\S+)/; $2!=@declstr_destrlim } { text }")
  Rules[:_s_DECLSTR_BODY] = rule_info("s_DECLSTR_BODY", "s_DECLSTR_BODYLINE*:slist { slist[1..-1].join('') }")
  Rules[:_declstr_body] = rule_info("declstr_body", "t_DECLSTR_BEGIN:tb s_DECLSTR_BODY:st c_spc_nl* t_DECLSTR_END {node(:str, tb, st)}")
  Rules[:_declstr] = rule_info("declstr", "constant_list:nc c_spc+ declstr_body:nb {node(:declstr, nc, nc, nb)}")
  Rules[:_assignment] = rule_info("assignment", "(local_assignment | invoke_assignment)")
  Rules[:_assign_rhs] = rule_info("assign_rhs", "arg_expr")
  Rules[:_local_assignment] = rule_info("local_assignment", "t_IDENTIFIER:ti c_spc_nl* t_ASSIGN:to c_spc_nl* assign_rhs:rhs {node(:lasgn, to, ti.sym, rhs)}")
  Rules[:_invoke_assignment_lhs] = rule_info("invoke_assignment_lhs", "(left_chained_invocations | invoke)")
  Rules[:_invoke_assignment] = rule_info("invoke_assignment", "invoke_assignment_lhs:lhs c_spc_nl* t_ASSIGN:to c_spc_nl* assign_rhs:rhs {   lhs.name = :\"\#{lhs.name}=\"   orig_arguments = lhs.arguments && lhs.arguments.body || []   arg_order = lhs.name==:\"[]=\" ? [*orig_arguments, rhs] : [rhs, *orig_arguments]   lhs.arguments = node(:argass, rhs, arg_order)   lhs }")
  Rules[:_invoke_body] = rule_info("invoke_body", "(c_spc_nl* param_list:n)?:np c_spc_nl* meme_enclosed_expr_body:nb { [np, nb] }")
  Rules[:_invoke] = rule_info("invoke", "t_IDENTIFIER:tn (c_spc* arg_list:na)?:na (c_spc_nl* invoke_body:n)?:nlist {node(:invoke, tn, nil, tn.sym, na, *nlist)}")
  Rules[:_op_invoke_id] = rule_info("op_invoke_id", "left_op_normal")
  Rules[:_op_invoke] = rule_info("op_invoke", "op_invoke_id:tn (c_spc* arg_list:na)?:na (c_spc_nl* invoke_body:n)?:nlist {node(:invoke, tn, nil, tn.sym, na, *nlist)}")
  Rules[:_elem_invoke] = rule_info("elem_invoke", "lit_array:na (c_spc_nl* invoke_body:n)?:nlist {node(:invoke, na, nil, :\"[]\", node(:argass, na, na.body), *nlist)}")
  Rules[:_arg_sep] = rule_info("arg_sep", "(c_spc* t_ARG_SEP c_spc*)+")
  Rules[:_arg_sep_opt] = rule_info("arg_sep_opt", "(c_spc | t_ARG_SEP)*")
  Rules[:_in_arg_normal] = rule_info("in_arg_normal", "(in_arg_splat | arg_expr:n0 !in_arg_kwarg_mark { n0 })")
  Rules[:_in_arg_normals] = rule_info("in_arg_normals", "in_arg_normal:n0 (arg_sep in_arg_normal:n)*:nrest { [n0,*nrest] }")
  Rules[:_in_arg_kwargs] = rule_info("in_arg_kwargs", "in_arg_kwarg:n0 (arg_sep in_arg_kwarg:n)*:nrest {node(:hash, n0.first, [n0,*nrest].flatten)}")
  Rules[:_in_arg_kwarg_mark] = rule_info("in_arg_kwarg_mark", "c_spc_nl* t_MEME_MARK:to")
  Rules[:_in_arg_kwarg] = rule_info("in_arg_kwarg", "id_as_symbol:n0 in_arg_kwarg_mark c_spc_nl* arg_expr:n1 { [n0, n1] }")
  Rules[:_in_arg_splat] = rule_info("in_arg_splat", "t_OP_MULT:to expr_atom:n0 {node(:splat, to, n0)}")
  Rules[:_in_arg_block] = rule_info("in_arg_block", "t_OP_TOPROC:to expr_atom:n0 {node(:blkarg, to, n0)}")
  Rules[:_in_arg_list] = rule_info("in_arg_list", "(in_arg_normals:n0 arg_sep in_arg_kwargs:n1 arg_sep in_arg_block:n2 { [*n0,n1,n2] } | in_arg_normals:n0 arg_sep in_arg_kwargs:n1 { [*n0,n1] } | in_arg_normals:n0 arg_sep in_arg_block:n1 { [*n0,n1] } | in_arg_kwargs:n0 arg_sep in_arg_block:n1 { [n0, n1] } | in_arg_normals:n0 { [*n0] } | in_arg_kwargs:n0 { [n0] } | in_arg_block:n0 { [n0] })")
  Rules[:_arg_list] = rule_info("arg_list", "(t_ARGS_BEGIN:tb arg_sep_opt t_ARGS_END {node(:argass, tb, [])} | t_ARGS_BEGIN:tb arg_sep_opt in_arg_list:nlist arg_sep_opt t_ARGS_END {node(:argass, tb, nlist)})")
  Rules[:_lit_array] = rule_info("lit_array", "(t_ARRAY_BEGIN:tb arg_sep_opt t_ARRAY_END {node(:arrass, tb, [])} | t_ARRAY_BEGIN:tb arg_sep_opt in_arg_list:nlist arg_sep_opt t_ARRAY_END {node(:arrass, tb, nlist)})")
  Rules[:_param] = rule_info("param", "(t_IDENTIFIER:ti c_spc_nl* t_ASSIGN:to c_spc_nl* arg_expr:nv { [:optional, node(:lasgn, ti, ti.sym, nv)] } | t_IDENTIFIER:ti c_spc_nl* t_MEME_MARK:to c_spc_nl* arg_expr?:nv { [:kwargs, node(:lasgn, ti, ti.sym, (nv || node(:lit, to, :*)))] } | t_OP_EXP c_spc_nl* t_IDENTIFIER:ti { [:kwrest,   ti.sym] } | t_OP_MULT c_spc_nl* t_IDENTIFIER:ti { [:rest,     ti.sym] } | t_OP_TOPROC c_spc_nl* t_IDENTIFIER:ti { [:block,    ti.sym] } | t_IDENTIFIER:ti { [:required, ti.sym] })")
  Rules[:_param_sepd] = rule_info("param_sepd", "arg_sep param:n0 { n0 }")
  Rules[:_param_sepds] = rule_info("param_sepds", "param:n0 (arg_sep param:n)*:nrest arg_sep_opt { [n0, *nrest] }")
  Rules[:_param_list] = rule_info("param_list", "(t_PARAMS_BEGIN:tb t_PARAMS_END { node(:args, tb, [], [], nil, [], [], nil, nil) } | t_PARAMS_BEGIN:tb param_sepds:plist t_PARAMS_END {       required, optional, rest, post, kwargs, kwrest, block = 7.times.map { [] }              required << plist.shift[1] while plist[0] && plist[0][0] == :required       optional << plist.shift[1] while plist[0] && plist[0][0] == :optional       rest     << plist.shift[1] while plist[0] && plist[0][0] == :rest       post     << plist.shift[1] while plist[0] && plist[0][0] == :required       kwargs   << plist.shift[1] while plist[0] && plist[0][0] == :kwargs       kwrest   << plist.shift[1] while plist[0] && plist[0][0] == :kwrest       block    << plist.shift[1] while plist[0] && plist[0][0] == :block              required = required       optional = optional       rest     = rest.first       post     = post       kwargs   = kwargs       kwrest   = kwrest.first       block    = block.first              \# TODO: move these conversions to their respective reductions       block = block && node(:blkprm, tb, block)              node(:args, tb, required, optional, rest, post, kwargs, kwrest, block)     })")
  Rules[:_left_op_normal] = rule_info("left_op_normal", "(t_OP_EXP | t_OP_MULT | t_OP_DIV | t_OP_MOD | t_OP_PLUS | t_OP_MINUS | t_OP_COMPARE)")
  Rules[:_left_op_branch] = rule_info("left_op_branch", "(t_OP_AND | t_OP_OR | t_OP_AND_Q | t_OP_OR_Q | t_OP_VOID_Q)")
  Rules[:_left_op] = rule_info("left_op", "(left_op_normal | left_op_branch)")
  Rules[:_left_chained_atoms] = rule_info("left_chained_atoms", "expr_atom:n0 (c_spc_nl* left_op:to c_spc_nl* expr_atom:n1 { [to, n1] })+:list {   list.unshift n0   list.flatten!      collapse(list, :t_OP_EXP)   collapse(list, :t_OP_MULT, :t_OP_DIV, :t_OP_MOD)   collapse(list, :t_OP_PLUS, :t_OP_MINUS)   collapse(list, :t_OP_COMPARE)   collapse(list, :t_OP_AND, :t_OP_OR,                  :t_OP_AND_Q, :t_OP_OR_Q, :t_OP_VOID_Q) do |n0,op,n1|     node(:branch_op, op, op.sym, n0, n1)   end      \# There should only be one resulting node left   raise \"Failed to fully collapse left_chained_atoms: \#{list}\" \\     unless list.count == 1      list.first }")
  Rules[:_left_invoke_op] = rule_info("left_invoke_op", "(t_QUEST | t_DOT)")
  Rules[:_left_chained_invocation] = rule_info("left_chained_invocation", "(c_spc_nl* left_invoke_op:to c_spc_nl* (invoke | op_invoke):n1 { [to, n1] } | c_spc* elem_invoke:n1 { [token(:t_DOT, \"\"), n1] })")
  Rules[:_left_chained_invocations] = rule_info("left_chained_invocations", "expr_atom_not_chained:n0 left_chained_invocation+:list {   list.unshift n0   list.flatten!      collapse(list, :t_DOT, :t_QUEST) do |n0,op,n1|     op.type==:t_DOT ? (n1.receiver=n0; n1) : node(:quest, op, n0, n1)   end      \# There should only be one resulting node left   raise \"Failed to fully collapse left_chained_invocations: \#{list}\" \\     unless list.count == 1      list.first }")
  Rules[:_unary_operation] = rule_info("unary_operation", "t_OP_NOT:to expr_atom:n0 {node(:invoke, to, n0, :\"!\", nil)}")
  Rules[:_t_inln_sep] = rule_info("t_inln_sep", "!t_ARG_SEP t_EXPR_SEP")
  Rules[:_inln_sep] = rule_info("inln_sep", "(c_spc* t_inln_sep c_spc*)+")
  Rules[:_inln_sep_opt] = rule_info("inln_sep_opt", "(c_spc | t_inln_sep)*")
  Rules[:_expr_sep] = rule_info("expr_sep", "(c_spc* t_EXPR_SEP c_spc*)+")
  Rules[:_expr_sep_opt] = rule_info("expr_sep_opt", "(c_spc | t_EXPR_SEP)*")
  Rules[:_meme_inline_sepd_exprs] = rule_info("meme_inline_sepd_exprs", "meme_expr:n0 (inln_sep meme_expr:n)*:nrest inln_sep_opt { [n0, *nrest] }")
  Rules[:_meme_sepd_exprs] = rule_info("meme_sepd_exprs", "meme_expr:n0 (expr_sep meme_expr:n)*:nrest expr_sep_opt { [n0, *nrest] }")
  Rules[:_meme_inline_expr_body] = rule_info("meme_inline_expr_body", "inln_sep_opt meme_inline_sepd_exprs:nlist {node(:block, nlist.first, nlist)}")
  Rules[:_meme_expr_body] = rule_info("meme_expr_body", "(expr_sep_opt meme_sepd_exprs:nlist t_MEME_END:te {node(:block, nlist.first, nlist)} | expr_sep_opt t_MEME_END:te {node(:null, te)})")
  Rules[:_paren_expr_body] = rule_info("paren_expr_body", "(expr_sep_opt meme_sepd_exprs:nlist t_PAREN_END:te { nlist.count==1 ? nlist.first : node(:block, nlist.first, nlist) } | expr_sep_opt t_PAREN_END:te {node(:null, te)})")
  Rules[:_paren_expr] = rule_info("paren_expr", "t_PAREN_BEGIN paren_expr_body:n0 { n0 }")
  Rules[:_meme_enclosed_expr_body] = rule_info("meme_enclosed_expr_body", "t_MEME_BEGIN meme_expr_body:n0 { n0 }")
  Rules[:_meme_either_body] = rule_info("meme_either_body", "(meme_enclosed_expr_body | meme_inline_expr_body)")
  Rules[:_cmeme] = rule_info("cmeme", "constant:n0 c_spc* t_MEME_MARK:tm c_spc_nl* meme_inline_expr_body:n1 {node(:cdecl, tm, n0, n1)}")
  Rules[:_meme_name] = rule_info("meme_name", "(id_as_symbol | lit_string_as_symbol)")
  Rules[:_decorator] = rule_info("decorator", "meme_name:ni arg_list?:na {node(:deco, ni, ni, (na ? node(:arrass, na, na.body) : nil))}")
  Rules[:_decorators_and_meme_name] = rule_info("decorators_and_meme_name", "decorator:n0 (c_spc* decorator:n)*:nrest {node(:arrass, n0, [n0, *nrest].reverse)}")
  Rules[:_meme] = rule_info("meme", "(decorators_and_meme_name:nd c_spc* t_MEME_MARK:tm (c_spc_nl* param_list:n)?:np c_spc_nl* meme_either_body:nb {node(:meme, tm, nd.body.shift.name, nd, np,  nb)} | decorators_and_meme_name:nd {node(:meme, tm, nd.body.shift.name, nd, nil, nil)})")
  # :startdoc:
end
