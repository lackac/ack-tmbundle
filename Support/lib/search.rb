#!/usr/bin/env ruby -rcgi

class AckInProject::Search
  include AckInProject::Environment
  AckInProject::Environment.ghetto_include %w(escape), binding

  attr_accessor :plist, :current_file, :lines_matched, :files_matched
  
  def initialize(plist)
    self.plist = plist;
    self.lines_matched = self.files_matched = 0
  end
  
  def line_matched
    self.lines_matched = lines_matched + 1
  end
  
  def file_matched
    self.files_matched = files_matched + 1
  end
  
  def h(string)
    CGI.escapeHTML(string)
  end

  def section_start(file)
    self.current_file = file
    reset_stripe
    file_matched
    puts %Q|<tr><th colspan="2"><a href="#" class="toggle" onclick="toggleLines(this, #{self.files_matched}); return false">-</a>#{current_file}<script>f();</script></th></tr>|
    puts %Q|<tbody class="matches" id="file-#{self.files_matched}">|
  end
  
  def section_end
    if current_file
      puts %Q|</tbody>|
      puts %Q|<tr><td>&nbsp;</td><td>&nbsp;</td></tr>|
    end
    self.current_file = nil
  end
  
  def linked_content(line, content)
    href = "txmt://open/?url=file://#{e_url file_in_search_directory(current_file)}&line=#{line}"
    %Q|<pre><a href="#{href}">#{scrub(escape(content))}</a></pre>|
  end
  
  def content_line(line, content)
    line_matched
    puts %Q|<tr class="content#{stripe}"><td>#{line}<script>l();</script></td><td>#{linked_content(line, content)}</td></tr>|
  end

  def context_line(line, content)
    puts %Q|<tr class="context#{stripe}"><td>#{line}</td><td>#{linked_content(line, content)}</td></tr>|
  end
  
  def context_break()
    reset_stripe
    puts %Q|<tr class="context break"><td>...</td><td>&nbsp;</td></tr>|
  end
  
  def stripe
    (@stripe = !@stripe) ? '' : ' stripe'
  end
  
  def reset_stripe
    @stripe = nil
  end
  
  def escape(content)
    CGI.escapeHTML(content)
  end

  def scrub(content)
    content.gsub(/\e\[\d+m\e\[K$/, '').
      gsub(/\e\[\d+;\d+m/, '<strong>').
      gsub(/\e\[\d+m/,'</strong>')
  end

  def prepare_search
    # TODO: bail if the search term is empty
    result = plist['result']
    
    options = %w(--group --color --flush --nopager)
    options << '-w' if result['matchWholeWords'] == 1
    options << '-i' if result['ignoreCase'] == 1
    options << '-Q' if result['literalMatch'] == 1
    options << '-C' if result['showContext'] == 1
    options << "--#{result['followSymLinks'] == 1 ? '' : 'no'}follow"
    options << "--#{result['loadAckRC'] == 1 ? '' : 'no'}env"

    AckInProject.update_search_history result['returnArgument']
    AckInProject.update_pbfind result['returnArgument']

    %{cd #{e_sh search_directory}; #{e_sh ack} #{options.join(' ')} #{e_sh result['returnArgument']}}
  end

  def find_rc_file
    # tell ack about potential .ackrc files in the project directory
    ackrc_home = File.join(ENV['HOME'], '.ackrc')
    if File.exists?(ackrc = File.join(project_directory, '.ackrc'))
      if File.exists?(ackrc_home)
        ackrc_merged = "#{ackrc}_merged"
        File.open(ackrc_merged, "w") do |f|
          f.puts '# ~/.ackrc'
          f.write(File.read(ackrc_home) + "\n")
          f.puts '# project .ackrc'
          f.write(File.read(ackrc) + "\n")
        end
        ackrc_merged
      else
        ackrc
      end
    else
      ackrc_home
    end
  end

  def search
    ENV['ACKRC'] = find_rc_file

    IO.popen(prepare_search) do |pipe|
      pipe.each do |line|
        case line
        when /^\s*$/
          section_end
        when /^\e\[\d+(?:;\d+)?m(.*)\e\[0m/
          section_start($1)
        when /^(\d+):(.*)$/
          content_line($1, $2)
        when /^(\d+)-(.*)$/
          context_line($1, $2)
        when /^--$/
          context_break
        end
        $stdout.flush
      end
      section_end
    end
  end
end
