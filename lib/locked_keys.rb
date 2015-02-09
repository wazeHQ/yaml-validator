class LockedKeys
  def initialize(root_path)
    @locked_patterns = []

    fullpath = File.join(root_path, 'locked_keys')
    if File.exist? fullpath
      read_locked_patterns(fullpath) unless File.directory?(fullpath)
    end
  end

  def locked?(full_key)
    @locked_patterns.each do |pattern|
      if full_key =~ pattern
        return true
      end
    end

    false
  end

private

  def read_locked_patterns(fullpath)
    File.open(fullpath) do |f|
      f.each_line do |line|
        next if line.empty? or line.start_with? '#'
        @locked_patterns << Regexp.new(line.rstrip)
      end
    end
  end
end
