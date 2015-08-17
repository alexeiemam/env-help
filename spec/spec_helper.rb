require 'coveralls'
Coveralls.wear!

require "rspec"
require "env_help"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.formatter = :doc
end

TEST_ENV =
  YAML.load_file(
    File.join(
      File.dirname(__FILE__),
      'fixtures',
      'mock.yml'
    )
  )

# module EnvHelp
#   module Tests
#     class Scenarios

#       module Data
#         SIMPLE_SINGLE =
#         {
#           zippadee: "value",
#           doooda: "0",
#           zippaddeweedaaaay: "thing",
#           hmm: "-45",
#           yessuh: "12",
#           nierp: ""
#         }

#         MULTI_SINGLE =
#         {
#           a: "1,2,3,4,5,6,7,8,9,0,-24242,a,5,bb56",
#           b: "Hey thre",
#           c: "yes,no,maybe,i-dont-know,can-you-repeat-the-question,true,off,false,nah,yeah,affirmative,negative",
#           d: "13824xXx77789xXx09843xXx-55",
#           e: "23..37",
#         }

#         BOOLY_COLLECTION =
#         {
#           vanguard_mode_destroy: "Yes",
#           vanguard_pos_mode: "negative",
#           prokofiev_music_mode: "yeah",
#           vanguard_mode_spy: "nah",
#           vanguard_mode_obliterate: "ON",
#           vanguard_mode_cover_my_tracks: "1",
#           vanguard_mode_love_the_world: "maybe next year"
#         }

#         STRINGY_COLLECTION =
#         {
#           :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_1 => "Serve the public trust",
#           :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_2 => "Protect the innocent",
#           :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_3 => "Uphold the law",
#           :iRobot_three_laws_law_1 => "A robot may not injure a human being or, through inaction, allow a human being to come to harm",
#           :iRobot_three_laws_law_2 => "A robot must obey the orders given to it by human beings, except where such orders would conflict with the First Law.",
#           :iRobot_three_laws_law_3 => "A robot must protect its own existence as long as such protection does not conflict with the First or Second Law"
#         }

#         MODDY_COLLECTION =
#         {
#           :ABC_a_xx_y => "0,1,2,3,4",
#           :ABC_b_ww_z => "5,6,7,8,9"
#         }

#         NESTED =
#         {
#           how:{deeply:{can:{you:{possibly:{nest:{this:{value:{that:{i:{need: "I'm not even an interesting value"}}}}}}}}}},
#           nested_robots: STRINGY_COLLECTION
#         }
#       end

#     class << self

#       def simple_single_presence_or(data, *args)
#         EnvHelp::Get::var :i_dont_exist, data, :to_sym, :or=,  "i_wish_i_existed"
#       end

#       def simple_single_in_or(data, *args)
#         EnvHelp::Get::var :a,{a:"Meerkat"}, :to_sym, :in, ["bobcat",2,:Zebu], :or=, 23
#       end

#       def multi_single_bool(data, *args)
#         # EnvHelp::Get::var :c, data, :split_to_array, :to_bool_with_fallback, false
#       end

#       def multi_single_num_split(data, *args)
#         # EnvHelp::Get::var :a, data, :split_to_array, :to_i_or=, -4, lambda{|x| x > -4 ? "#{x} is a number" : x.to_s}
#       end

#       def multi_single_num_split_with_char(data, *args)
#         # EnvHelp::Get::var :d, data, :split_to_array, "xXx", :to_i_or=, :do_not_want
#       end

#       def multi_single_num_range(data, *args)
#         EnvHelp::Get::var :a, data, :rangey_or=, -1..16, :in, 0..12, :or=, :you_lose
#       end

#       def stringy_collection_lambda_select(data, *args)
#         EnvHelp::Get::var_collection lambda{|k| k.to_s =~ /robo.*/i && k.to_s.last(1).split(//).try(:last).try(:to_i).try(:>, 1)}, data
#       end

#       def string_collection_regexp_select(data, *args)
#         EnvHelp::Get::var_collection /robo.*3/i, data
#       end

#       def stringy_collection_unprefix_lambda_replace_1(data, *args)
#         EnvHelp::Get::var_collection :iRobot_three_laws_, data, :un_prefix_keys, lambda{|s| s.to_s.sub('must', 'must not').sub('may not', 'should definitely').sub('human beings', 'wretched meatbags')}
#       end

#       def stringy_collection_unprefix_lambda_replace_2(data, *args)
#         EnvHelp::Get::var_collection :ROBOCOP_PRIME_DIRECTIVES_, data, :un_prefix_keys, lambda{|s| s.to_s.sub('Serve', 'Abuse').sub('Protect', 'Take advantage of').sub('Uphold', 'Break')}
#       end

#       def moddy_collection_mod_mod(data, *args)
#         EnvHelp::Get::var_collection :ABC_, data,
#           :un_prefix_keys, :downcase_keys, :mod_keys, lambda {|k| k.to_s.gsub('_','/')},
#           :split_to_array, lambda {|vs| vs.map(&:to_i)}
#       end

#       def booly_collection_to_num_collection(data, *args)
#         # EnvHelp::Get::var_collection :vanguard_mode_, data, :un_prefix_keys, :to_bool_with_fallback, false, :to_i_or=, -666
#       end

#       def booly_collection_lambda_replace(data, *args)
#         EnvHelp::Get::var_collection :vanguard_mode_, data, :un_prefix_keys, :to_bool_with_fallback, false, lambda{|b| b ? "Yes commander" : "Negative, captain"}
#       end

#       def numbery(data, *args)
#         EnvHelp::Get::var :a, data, :to_i_or=, 3, :if_satisfies, lambda{|x| x > -4}, :or=, 9, lambda{|x| "forget you I don't do what you t#{x}ll me"}
#       end

#       def nested_key(data, *args)
#         EnvHelp::Get::var(:"[how][deeply][can][you][possibly][nest][this][value][that][i][need]", data, :or=, "everything is illuminated")
#       end

#       def vars_by_config(data, *args)
#         config = {
#           a: [:split_to_array, :to_i, :in, -4..5, :or=, 99 ],
#           # d: [:split_to_array, "xXx", :to_i_or=, :do_not_want],
#           robos_replaced: [:var_collection, :ROBOCOP_PRIME_DIRECTIVES_, :un_prefix_keys, lambda{|s| s.to_s.sub('Serve', 'Abuse').sub('Protect', 'Take advantage of').sub('Uphold', 'Break')}],
#           robo_3s: [:var_collection, /robo.*3/i],
#           nested_prefixes: [:var_collection, :"[nested_robots][ROBOCOP_PRIME_DIRECTIVES_]", :un_prefix_keys]
#         }
#         EnvHelp::Get::vars_by_config config, data
#       end

#       def value_from_env(*_)
#         ENV["EnvHelpTestString"] = "a,b,c,d,e,f,g,h,j,i,1,2,3,4,5,6,7,8,9"
#         EnvHelp::Get::var :EnvHelpTestString, :split_to_array, :to_i, :compact
#         # before compact
#         # => [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1, 2, 3, 4, 5, 6, 7, 8, 9]
#         # after compact
#         # => [1, 2, 3, 4, 5, 6, 7, 8, 9]
#       end

#       def db_config(*_)
#         data = {
#           db2: "mysql2://mister:password@example.org:3309/test?reconnect=false&pool=17"
#         }
#         EnvHelp::Get::var :db2, data, :connection_config
#       end

#     end
#     end

#     class Run

#       SCENARIOR = EnvHelp::Tests::Scenarios
#       SCENARIOS = SCENARIOR.methods(false)
#       DATA_MONSTER = EnvHelp::Tests::Scenarios::Data
#       DATA_KEYS = DATA_MONSTER.constants

#       class << self
#       def all(*args)
#         SCENARIOS.each_with_object({}) {|s,o| o[s] = activate(s, *args)}
#       end

#       def data(key)
#         DATA_KEYS.include?(key) ?
#           DATA_MONSTER.const_get(key) :
#           nil
#       end

#       def datasplodge
#         DATA_KEYS.each_with_object({}) {|k,o| o.merge! DATA_MONSTER.const_get(k)}
#       end

#       private

#       def activate(n, *args)
#         first_bit, second_bit, *others = n.to_s.split("_")
#         scenario_data =
#           data([first_bit, second_bit].join("_").to_s.upcase.to_sym) ||
#           datasplodge
#         SCENARIOR.send(n, scenario_data, *args)
#       end

#       def method_missing(name, *args)
#         activate(name, *args)
#       end
#       end

#     end
#   end
# end