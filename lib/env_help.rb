# v0.2
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
            try(:in?, [:true,:"1",:enabled,:yes,:live,:on,:yeah,:yep,:positive,:affirmative,:y]) ||
            fallback_value
        end

        def false_bool_from_string_with_fallback(value, fallback_value=nil, *args)
          determined_bool =
          value.
            try(:to_s).try(:downcase).try(:to_sym).
            try(:in?, [:false,:"0",:disabled,:no,:dead,:off,:nah,:nope,:negative,:n,:nyet]).
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
        hash = hash.with_indifferent_access
        while nodes.count > 1
          node = nodes.shift
          hash = hash.try(:[], node.to_s)
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

module EnvHelp
  module Tests
    class Scenarios

      module Data
        SIMPLE_SINGLE =
        {
          zippadee: "value",
          doooda: "0",
          zippaddeweedaaaay: "thing",
          hmm: "-45",
          yessuh: "12",
          nierp: ""
        }

        MULTI_SINGLE =
        {
          a: "1,2,3,4,5,6,7,8,9,0,-24242,a,5,bb56",
          b: "Hey thre",
          c: "yes,no,maybe,i-dont-know,can-you-repeat-the-question,true,off,false,nah,yeah,affirmative,negative",
          d: "13824xXx77789xXx09843xXx-55",
          e: "23..37",
        }

        BOOLY_COLLECTION =
        {
          vanguard_mode_destroy: "Yes",
          vanguard_pos_mode: "negative",
          prokofiev_music_mode: "yeah",
          vanguard_mode_spy: "nah",
          vanguard_mode_obliterate: "ON",
          vanguard_mode_cover_my_tracks: "1",
          vanguard_mode_love_the_world: "maybe next year"
        }

        STRINGY_COLLECTION =
        {
          :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_1 => "Serve the public trust",
          :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_2 => "Protect the innocent",
          :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_3 => "Uphold the law",
          :iRobot_three_laws_law_1 => "A robot may not injure a human being or, through inaction, allow a human being to come to harm",
          :iRobot_three_laws_law_2 => "A robot must obey the orders given to it by human beings, except where such orders would conflict with the First Law.",
          :iRobot_three_laws_law_3 => "A robot must protect its own existence as long as such protection does not conflict with the First or Second Law"
        }

        MODDY_COLLECTION =
        {
          :ABC_a_xx_y => "0,1,2,3,4",
          :ABC_b_ww_z => "5,6,7,8,9"
        }

        NESTED =
        {
          how:{deeply:{can:{you:{possibly:{nest:{this:{value:{that:{i:{need: "I'm not even an interesting value"}}}}}}}}}},
          nested_robots: STRINGY_COLLECTION
        }
      end

    class << self

      def simple_single_presence_or(data, *args)
        EnvHelp::Get::var :i_dont_exist, data, :to_sym, :or=,  "i_wish_i_existed"
      end

      def simple_single_in_or(data, *args)
        EnvHelp::Get::var :a,{a:"Meerkat"}, :to_sym, :in, ["bobcat",2,:Zebu], :or=, 23
      end

      def multi_single_bool(data, *args)
        # EnvHelp::Get::var :c, data, :split_to_array, :to_bool_with_fallback, false
      end

      def multi_single_num_split(data, *args)
        # EnvHelp::Get::var :a, data, :split_to_array, :to_i_or=, -4, lambda{|x| x > -4 ? "#{x} is a number" : x.to_s}
      end

      def multi_single_num_split_with_char(data, *args)
        # EnvHelp::Get::var :d, data, :split_to_array, "xXx", :to_i_or=, :do_not_want
      end

      def multi_single_num_range(data, *args)
        EnvHelp::Get::var :a, data, :rangey_or=, -1..16, :in, 0..12, :or=, :you_lose
      end

      def stringy_collection_lambda_select(data, *args)
        EnvHelp::Get::var_collection lambda{|k| k.to_s =~ /robo.*/i && k.to_s.last(1).split(//).try(:last).try(:to_i).try(:>, 1)}, data
      end

      def string_collection_regexp_select(data, *args)
        EnvHelp::Get::var_collection /robo.*3/i, data
      end

      def stringy_collection_unprefix_lambda_replace_1(data, *args)
        EnvHelp::Get::var_collection :iRobot_three_laws_, data, :un_prefix_keys, lambda{|s| s.to_s.sub('must', 'must not').sub('may not', 'should definitely').sub('human beings', 'wretched meatbags')}
      end

      def stringy_collection_unprefix_lambda_replace_2(data, *args)
        EnvHelp::Get::var_collection :ROBOCOP_PRIME_DIRECTIVES_, data, :un_prefix_keys, lambda{|s| s.to_s.sub('Serve', 'Abuse').sub('Protect', 'Take advantage of').sub('Uphold', 'Break')}
      end

      def moddy_collection_mod_mod(data, *args)
        EnvHelp::Get::var_collection :ABC_, data,
          :un_prefix_keys, :downcase_keys, :mod_keys, lambda {|k| k.to_s.gsub('_','/')},
          :split_to_array, lambda {|vs| vs.map(&:to_i)}
      end

      def booly_collection_to_num_collection(data, *args)
        # EnvHelp::Get::var_collection :vanguard_mode_, data, :un_prefix_keys, :to_bool_with_fallback, false, :to_i_or=, -666
      end

      def booly_collection_lambda_replace(data, *args)
        EnvHelp::Get::var_collection :vanguard_mode_, data, :un_prefix_keys, :to_bool_with_fallback, false, lambda{|b| b ? "Yes commander" : "Negative, captain"}
      end

      def numbery(data, *args)
        EnvHelp::Get::var :a, data, :to_i_or=, 3, :if_satisfies, lambda{|x| x > -4}, :or=, 9, lambda{|x| "forget you I don't do what you t#{x}ll me"}
      end

      def nested_key(data, *args)
        EnvHelp::Get::var(:"[how][deeply][can][you][possibly][nest][this][value][that][i][need]", data, :or=, "everything is illuminated")
      end

      def vars_by_config(data, *args)
        config = {
          a: [:split_to_array, :to_i, :in, -4..5, :or=, 99 ],
          # d: [:split_to_array, "xXx", :to_i_or=, :do_not_want],
          robos_replaced: [:var_collection, :ROBOCOP_PRIME_DIRECTIVES_, :un_prefix_keys, lambda{|s| s.to_s.sub('Serve', 'Abuse').sub('Protect', 'Take advantage of').sub('Uphold', 'Break')}],
          robo_3s: [:var_collection, /robo.*3/i],
          nested_prefixes: [:var_collection, :"[nested_robots][ROBOCOP_PRIME_DIRECTIVES_]", :un_prefix_keys]
        }
        EnvHelp::Get::vars_by_config config, data
      end

      def value_from_env(*_)
        ENV["EnvHelpTestString"] = "a,b,c,d,e,f,g,h,j,i,1,2,3,4,5,6,7,8,9"
        EnvHelp::Get::var :EnvHelpTestString, :split_to_array, :to_i, :compact
        # before compact
        # => [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        # after compact
        # => [1, 2, 3, 4, 5, 6, 7, 8, 9]
      end

    end
    end

    class Run

      SCENARIOR = EnvHelp::Tests::Scenarios
      SCENARIOS = SCENARIOR.methods(false)
      DATA_MONSTER = EnvHelp::Tests::Scenarios::Data
      DATA_KEYS = DATA_MONSTER.constants

      class << self
      def all(*args)
        SCENARIOS.each_with_object({}) {|s,o| o[s] = activate(s, *args)}
      end

      def data(key)
        DATA_KEYS.include?(key) ?
          DATA_MONSTER.const_get(key) :
          nil
      end

      def datasplodge
        DATA_KEYS.each_with_object({}) {|k,o| o.merge! DATA_MONSTER.const_get(k)}
      end

      private

      def activate(n, *args)
        first_bit, second_bit, *others = n.to_s.split("_")
        scenario_data =
          data([first_bit, second_bit].join("_").to_s.upcase.to_sym) ||
          datasplodge
        SCENARIOR.send(n, scenario_data, *args)
      end

      def method_missing(name, *args)
        activate(name, *args)
      end
      end

    end
  end
end

EH = EnvHelp
