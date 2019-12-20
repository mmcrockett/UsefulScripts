def compare(a, b, prefix = '')
  b.keys.each do |k|
    if (false == a.include?(k))
      puts "E: #{prefix}:#{k}"
    end
  end

  a.each do |k,v|
    if (false == b.include?(k))
      puts "M: #{prefix}:#{k}"
    elsif (v.class != b[k].class)
      puts "X: #{prefix}:#{k}:#{v.class}:#{b[k].class}"
    elsif (v.is_a?(Hash))
      compare(v, b[k], "#{prefix}:#{k}")
    end
  end
end
