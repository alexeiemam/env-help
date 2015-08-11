unless Object.instance_methods.include?(:try)

class Object
  def try(*a, &b)
    try!(*a, &b) if a.empty? || respond_to?(a.first)
  end

  def try!(*a, &b)
    if a.empty? && block_given?
      if b.arity.zero?
        instance_eval(&b)
      else
        yield self
      end
    else
      public_send(*a, &b)
    end
  end
end

end

unless Object.instance_methods.include?(:presence)

class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  def present?
    !blank?
  end

  def presence
    self if present?
  end
end

end

unless Object.instance_methods.include?(:in?)

class Object
  def in?(another_object)
    another_object.include?(self)
  rescue NoMethodError
    raise ArgumentError.new("The parameter passed to #in? must respond to #include?")
  end

  def presence_in(another_object)
    self.in?(another_object) ? self : nil
  end
end

end

unless String.instance_methods.include?(:starts_with?)
  class String
    def starts_with?(prefix)
      prefix.respond_to?(:to_str) && self[0, prefix.length] == prefix
    end
  end
end

unless String.instance_methods.include?(:ends_with?)
  class String
    def ends_with?(suffix)
      suffix.respond_to?(:to_str) && self[-suffix.length, suffix.length] == suffix
    end
  end
end

unless String.instance_methods.include?(:last)
  class String
    def last(limit = 1)
      if limit == 0
        ''
      elsif limit >= size
        self.dup
      else
        from(-limit)
      end
    end
  end
end

unless String.instance_methods.include?(:from)
  class String
    def from(position)
      self[position..-1]
    end
  end
end
