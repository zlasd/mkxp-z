# Run with the Ruby 3 interpreter used by mkxp-z.
raise 'This regression requires Ruby 3' if RUBY_VERSION.to_i < 3

source = <<~'RUBY'
  def classic_dash?(blocked)
    return false if blocked
  else return true
  end
  def classic_begin
    begin
      value = 1
    else
      value += 2
    ensure
      value += 4
    end
    value
  end
RUBY
valid = <<~'RUBY'
  def normal_branch(value)
    if value
      :yes
    else
      :no
    end
  end
  def rescued_branch
    begin
      1
    rescue
      :error
    else
      :ok
    end
  end
  TEXT = <<~'TEXT'
  else return true
  TEXT
  # else without rescue is useless
RUBY
malformed = "def broken\nelse return true\nend\ndef missing_end\n"
$RGSS_SCRIPTS = [[0, 'Classic', nil, source], [1, 'Normal', nil, valid],
                 [2, 'Broken', nil, malformed]]
preload = File.expand_path('../scripts/preload/ruby_classic_wrap.rb', __dir__)
original_verbose = $VERBOSE
load preload
normalized = $RGSS_SCRIPTS[0][3]
raise 'compatibility not applied' if normalized == source
raise 'line numbers changed' unless normalized.lines.length == source.lines.length
raise 'valid script modified' unless $RGSS_SCRIPTS[1][3] == valid
raise 'unrelated syntax error masked' unless $RGSS_SCRIPTS[2][3] == malformed
raise 'warning state leaked' unless $VERBOSE == original_verbose
load preload
raise 'not idempotent' unless normalized == $RGSS_SCRIPTS[0][3]
eval(normalized)
eval(valid)
raise 'early return changed' unless classic_dash?(true) == false
raise 'else continuation changed' unless classic_dash?(false) == true
raise 'ensure changed' unless classic_begin == 7
raise 'valid branches changed' unless normal_branch(false) == :no && rescued_branch == :ok
puts 'Classic Ruby syntax regression passed'
