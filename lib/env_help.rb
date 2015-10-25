require 'core_ext/overrides'

module EnvHelp
  module Types
    class Stringy
    class << self

      def split_to_array(value, *modifiers)
        separator, modifiers = modifiers
        separator = separator.is_a?(String) ? separator : ","
        [*(value.presence.try(:split, separator.to_s))]
      end

    end
    end

    class StructuredObjects

    require 'uri'
    require 'yaml'
    require 'ostruct'

    class << self

      def connection_struct(value, *args)
        return nil unless value
        begin
          OpenStruct.new connection_hash(value, *args)
        rescue
         return nil
        end
      end

      def connection_hash(value, *args)
        return nil unless value
        begin
          # see https://github.com/rails/rails/pull/13582/files
          ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(value).to_hash.with_indifferent_access
        rescue
          begin
            # Adapted From https://gist.github.com/pricees/9630464
            uri    = URI.parse(value)

            qs     = Hash[URI::decode_www_form(uri.query)]
            ui     = uri.userinfo.split(':')

            {
              encoding:   qs['encoding'] || 'utf-8',
              adapter:    uri.scheme,
              host:       uri.host,
              port:       uri.port || 3306,
              database:   uri.path[1..-1],
              username:   ui.first,
              password:   ui.last,
              reconnect:  qs['reconnect'] || true,
              pool:       qs['pool'] || 5
            }
          rescue
            return nil
          end
        end
      end

    end
    end

    class Numeric
    class << self

      def integer_like(value, *args)
        (value == "0")    ? 0   : # only accept 0 when explicitly entered
        (value.to_i == 0) ? nil : # .to_i returns 0 on nils/non-numeric strings
        value.to_i
      end

      def float_like(value, *args)
        ((value == "0.0") || (value == "0"))    ? 0.0   : # only accept 0 when explicitly entered
        (value.to_f == 0.0) ? nil : # .to_f returns 0 on nils/non-numeric strings
        value.to_f
      end

      def more_than(value, more_than_this, *args)
        an_int = integer_like(value)
        return nil unless an_int && (an_int > more_than_this)
        an_int
      end

      def less_than(value, less_than_this, *args)
        an_int = integer_like(value)
        return nil unless an_int && (an_int < less_than_this)
        an_int
      end

      def negative_int(value, *args)
        less_than(value, -1)
      end

      def non_negative_int(value, *args)
        more_than(value, -1)
      end

      def positive_int(value, *args)
        more_than(value, 0)
      end

      alias_method :to_i, :integer_like

      def rangey(value, *args)
        case value.to_s
        when /(\d+)\.\.(\d+)/
          mode = :range
          # collection = *(($1.to_i)..($2.to_i))
          collection = ($1.to_i)..($2.to_i)
        when /([\d+],)+(\d+)/
          mode = :collection
          collection = value.split(",").map(&:to_i)
        when /\A(?!-)(\d+)\z/
          mode = :single
          collection = [value.to_i]
        else
          mode = :bork
          collection = []
        end
        collection
      end

    end
    end
    class Boolean
      class << self

        def true_bool_from_string_with_fallback(value, fallback_value=nil, *args)
          value.
            try(:to_s).try(:downcase).try(:to_sym).
            try(:in?, [:true,:t,:"1",:enabled,:yes,:live,:on,:yeah,:yep,:positive,:affirmative,:y]) ||
            fallback_value
        end

        def false_bool_from_string_with_fallback(value, fallback_value=nil, *args)
          determined_bool =
          value.
            try(:to_s).try(:downcase).try(:to_sym).
            try(:in?, [:false,:f,:"0",:disabled,:no,:dead,:off,:nah,:nope,:negative,:n,:nyet]).
            try(:!)
          (determined_bool == false) ? determined_bool : fallback_value
        end

        def true_unless_false_ish(value, *args)
          return true unless (to_bool(value) == false)
          false
        end

        def false_unless_true_ish(value, *args)
          return false unless (to_bool(value) == true)
          true
        end

        def to_bool(value, *args)
          return false if false_bool_from_string_with_fallback(value, nil) == false
          return true if true_bool_from_string_with_fallback(value, nil) == true
          nil
        end

        def to_bool_with_fallback(value, fallback, *args)
          raise "Fallback value must be of boolean type, #{value} is a #{value.class}" unless
            ((fallback == true) || (fallback ==false))
          return fallback if to_bool(value).nil?
          to_bool(value)
        end

      end
    end
    class Collectiony
    class << self

      def un_prefix_keys(values, prefix, *modifiers)
        mod = lambda {|k| k.to_s.sub(prefix.to_s,'').to_sym}
        mod_keys(values, prefix, mod, *modifiers)
      end

      def downcase_keys(values, prefix, *modifiers)
        mod = lambda {|k| k.to_s.downcase.to_sym}
        mod_keys(values, prefix, mod, *modifiers)
      end

      def mod_keys(values, prefix, key_modifier, *modifiers)
        values.each_with_object({}) do |(k,v),o|
          nu_key = key_modifier.call(k)
          o[nu_key] = v
        end
      end

      def to_struct(hashlike, *modifiers)
        Struct.new(*(hashlike.keys)).new(*(hashlike.values))
      end

      def to_ostruct(hashlike, *modifiers)
        OpenStruct.new(hashlike)
      end

      def compact(values, *modifiers)
        if values.is_a?(Array)
          return values.compact
        end
        if values.is_a?(Hash)
          return values.each_with_object({}) do |(k,v),o|
            o[nu_key] = v unless v.nil?
          end
        end
        return values
      end

      def collection_send(values, prefix, *modifiers)
        values.each_with_object({}) do |(k,v),o|
          o[k] = EnvHelp::Get::mod_sequence(v, *modifiers)
        end
      end

      def array_send(values, *modifiers)
        values.map do |v|
          EnvHelp::Get::mod_sequence(v, *modifiers)
        end
      end

    end
    end
    class Switch
    class << self

      def if(value, implicated_condition, conditioner, *modifiers)
        EnvHelp::Types::Operant.send(implicated_condition, value, conditioner)
      end

    end
    end
    class Operant
    class << self

      def in(value, array, *modifiers)
        return nil unless (value.in? array)
        value
      end

      alias_method :in_range, :in

      def regexp_match(value, matcher, *modifiers)
        return nil unless value.to_s =~ matcher
        value
      end

      def proc_match(value, matcher, *modifiers)
        return nil unless (matcher.call value)
        return value
      end


      def fallback_to(value, fallback, *args)
        return value if value == false
        value.presence || fallback
      end

      alias_method :or=, :fallback_to

      def satisfies(value, satisfier, *modifiers)
        case
        when satisfier.respond_to?(:call)
          return proc_match(value, satisfier)
        when (satisfier.is_a?(Array) || satisfier.is_a?(Range))
          return self.in(value, satisfier)
        when satisfier.is_a?(Regexp)
          return regexp_match(value.to_s, satisfier)
        when satisfier == true
          return value
        when satisfier == false
          return nil
        else
          return EnvHelp::Get::mod_sequence(value, satisfier , *modifiers)
        end
      end

    end
    end
  end
  class Get
    AVAILABLE_CLASSES = Types.constants.select {|c| Class === Types.const_get(c)}
    AVAILABLE_METHODS =  AVAILABLE_CLASSES.
      map {|cname| Types.const_get(cname)}.
      map {|c| [c, c.methods(false)]}

    class << self

      def var(key, *args)
        base_hash =
          (args.count > 0) && (args.first.is_a?(Hash)) ?
            args.shift :
            ENV.to_hash
        brains = _the_key_and_hash(key, base_hash)
        return _get(brains.key, brains.hash, *args)
      end

      def var_collection(key_prefix, *args)
        base_hash =
          (args.count > 0) && (args.first.is_a?(Hash)) ?
            args.shift :
            ENV.to_hash
        brains = _the_key_and_hash(key_prefix, base_hash)
        return _get_collection(brains.key, brains.hash, *args)
      end

      alias_method :all_from, :var_collection

      def any_from(key_array, *args)
        key_array.each do |k,o|
          determined_value = var(k, *args)
          return determined_value unless determined_value.nil?
        end
        nil
      end

      def vars_by_config(config, *args)
        potential_source_hash, *rest = args
        source_hash = (potential_source_hash.is_a?(Hash)) ? potential_source_hash : ENV.to_hash
        config.each_with_object({}) do |(key, config_args), ret|
          first_arg, *not_first_args = config_args
          source_var_or_collection = (first_arg == :var_collection) ? :var_collection : :var
          if source_var_or_collection == :var_collection
            selector, *collection_configs = not_first_args
            ret[key] = send(source_var_or_collection, selector, source_hash, *collection_configs)
          else
            ret[key] = send(source_var_or_collection, key, source_hash, *config_args)
          end
        end
      end

      def mod_sequence(v, *mods)
        meth = mods.shift
        argos = mods
        # meth, argos = *mods
        return method_parent(meth).send(meth, v, *argos) if method_parent(meth)
        proc_args = v#([v]+[*argos])#.compact
        return (meth.call v) if meth.respond_to?(:call)
        return v.try(meth) if (meth.is_a?(Symbol) && v.respond_to?(meth))
        return v
      end

      private

      def _get(key, source_hash, *args)
        source_hash = source_hash.with_indifferent_access if source_hash.respond_to?(:with_indifferent_access)
        value = source_hash[key]
        return value if args.count < 1
        while args.count > 0 do
          args_in_use = []
          meth, *args = args
          if meth.is_a?(Symbol)
            case
            when method_parent(meth).try(:name) =~ /operant/i
              args_in_use = [args.shift]
            when meth.to_s.ends_with?('_or=')
              meth = meth.to_s.gsub('_or=','').to_sym
              args.unshift(:fallback_to)
              args_in_use = []
            when meth.to_s.starts_with?('if_')
              conditioner = meth.to_s.gsub('if_','').to_sym
              condition_object = args.shift
              meth = :if
              args_in_use = [conditioner, condition_object]
            else
              args_in_use = args
            end
          end
          value = if (value.is_a?(Array) || value.is_a?(Range)) && value.present? && !(method_parent(meth).try(:name) =~ /Collectiony/)
             Types::Collectiony::array_send(value, meth, *args_in_use)
          else
            mod_sequence(value, meth,*args_in_use)
          end
        end
        value
      end

      def _get_collection(key_prefix, source_hash, *args)
        values = source_hash.each_with_object({}) do |(k,v),o|
          o[k] = v if _key_match(k, key_prefix)
        end
        return values if args.count < 1
        while args.count > 0 do
          args_in_use = []
          meth, *args = args
          if meth.is_a?(Symbol)
            case
            when method_parent(meth).try(:name) =~ /operant/i
              args_in_use = [args.shift]
            when meth.to_s.ends_with?('_or=')
              meth = meth.to_s.gsub('_or=','').to_sym
              args.unshift(:fallback_to)
              args_in_use = []
            when meth.to_s.starts_with?('if_')
              conditioner = meth.to_s.gsub('if_','').to_sym
              condition_object = args.shift
              meth = :if
              args_in_use = [conditioner, condition_object]
            when meth.to_s =~ /mod_keys/i
              keymodder = args.shift
              args_in_use = [keymodder]
            else
              args_in_use = args
            end
          end
          values = if method_parent(meth).try(:name) =~ /Collectiony/
            mod_sequence(values, meth, key_prefix, *args_in_use)
          else
            Types::Collectiony::collection_send(values, key_prefix, meth, *args_in_use)
          end
        end
        values
      end

      def _the_key_and_hash(key, hash)
        return _key_hash(key, hash) unless key.is_a?(Symbol)
        keys = (key.to_s.scan /\[(.*?)\]/).collect(&:first)
        return _key_hash(key, hash) unless keys.count > 0
        return _hash_dive(keys, hash)
      end

      def _key_hash(key, hash)
        Struct.new(:key, :hash).new(key, hash)
      end

      def _hash_dive(nodes, hash)
        hash ||= {}
        hash = hash.with_indifferent_access if hash.respond_to?(:with_indifferent_access)
        while nodes.count > 1
          node = nodes.shift
          hash = hash.try(:[], node.to_s) || hash.try(:[], node.to_s.to_sym)
        end
        hash ||= {}
        _key_hash(nodes.first.to_sym, hash)
      end

      def _key_match(key, matcher)
        return key.to_s =~ matcher if matcher.is_a?(Regexp)
        return matcher.call key if matcher.is_a?(Proc)
        return key.to_s.in?(matcher.map(&:to_s)) if matcher.is_a?(Array)
        return key.to_s.starts_with?(matcher.to_s)
      end

      def method_parent(meth)
        AVAILABLE_METHODS.each do |pm|
          papa, meths = pm
          return papa if meths.include?(meth.to_s.to_sym)
        end
        nil
      end

    end
  end
end

EH = EnvHelp
