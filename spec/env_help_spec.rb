require "spec_helper"

RSpec.describe EnvHelp do
  it "uses fallback when specified and key not present" do
    result =
      EnvHelp::Get::var :i_dont_exist, TEST_ENV,
        :to_sym, :or=,  "i_wish_i_existed"

    expect(result).to eq("i_wish_i_existed")
  end

  it "uses fallback when specified and key not present" do
    result =
      EnvHelp::Get::var :a, TEST_ENV,
        :to_sym, :in, ["bobcat",2,:Zebu], :or=, 23
    expect(result).to eq(23)
  end

  it "allows parsing by configuration hash" do
    config = {
          a: [:split_to_array, :to_i, :in, -4..5, :or=, 99 ],
          # d: [:split_to_array, "xXx", :to_i_or=, :do_not_want],
          robos_replaced: [:var_collection, :ROBOCOP_PRIME_DIRECTIVES_, :un_prefix_keys, lambda{|s| s.to_s.sub('Serve', 'Abuse').sub('Protect', 'Take advantage of').sub('Uphold', 'Break')}],
          robo_3s: [:var_collection, /robo.*3/i],
          nested_prefixes: [:var_collection, :"[nested_robots][ROBOCOP_PRIME_DIRECTIVES_]", :un_prefix_keys]
        }
    result = EnvHelp::Get::vars_by_config config, TEST_ENV
    expect(result).to eq({
      :a=>[1, 2, 3, 4, 5, 99, 99, 99, 99, 0, 99, 99, 5, 99], :robos_replaced=>{:DIRECTIVE_1=>"Abuse the public trust", :DIRECTIVE_2=>"Take advantage of the innocent", :DIRECTIVE_3=>"Break the law"}, :robo_3s=>{:ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_3=>"Uphold the law", :iRobot_three_laws_law_3=>"A robot must protect its own existence as long as such protection does not conflict with the First or Second Law"}, :nested_prefixes=>{:DIRECTIVE_1=>"Serve the public trust", :DIRECTIVE_2=>"Protect the innocent", :DIRECTIVE_3=>"Uphold the law"}
    })
  end

  it "allows access to nested keys" do
    result =
      EnvHelp::Get::var :"[how][deeply][can][you][possibly][nest][this][value][that][i][need]",
        TEST_ENV, :or=, "everything is illuminated"
    expect(result).to eq("I'm not even an interesting value")
  end

  it "allows number range parsing" do
    result =
      EnvHelp::Get::var :a, TEST_ENV,
        :rangey_or=, -1..16, :in, 0..12, :or=, :you_lose

    expect(result).to eq([1, 2, 3, 4, 5, 6, 7, 8, 9, 0, :you_lose, 0, 5, 0])
  end
  # def multi_single_num_range(TEST_ENV, *args)
  # end

  it "allows lambda select" do
    result =
      EnvHelp::Get::var_collection lambda{|k| k.to_s =~ /robo.*/i && k.to_s.last(1).split(//).try(:last).try(:to_i).try(:>, 1)}, TEST_ENV

    expect(result).to eq({
      :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_2=>"Protect the innocent",
      :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_3=>"Uphold the law",
      :iRobot_three_laws_law_2=>"A robot must obey the orders given to it by human beings, except where such orders would conflict with the First Law.",
      :iRobot_three_laws_law_3=>"A robot must protect its own existence as long as such protection does not conflict with the First or Second Law"
      })
  end

  it "allows regex select" do
    result =
      EnvHelp::Get::var_collection /robo.*3/i, TEST_ENV
    expect(result).to eq({
      :ROBOCOP_PRIME_DIRECTIVES_DIRECTIVE_3=>"Uphold the law",
      :iRobot_three_laws_law_3=>"A robot must protect its own existence as long as such protection does not conflict with the First or Second Law"
      })
  end


  it "allows unprefixing with lambda replacement" do
    result =
      EnvHelp::Get::var_collection :iRobot_three_laws_, TEST_ENV,
        :un_prefix_keys,
        lambda{|s| s.to_s.sub('must', 'must not').sub('may not', 'should definitely').sub('human beings', 'wretched meatbags')}
    expect(result).to eq({
      :law_1=>"A robot should definitely injure a human being or, through inaction, allow a human being to come to harm",
      :law_2=>"A robot must not obey the orders given to it by wretched meatbags, except where such orders would conflict with the First Law.",
      :law_3=>"A robot must not protect its own existence as long as such protection does not conflict with the First or Second Law"
      })
  end


  it "allows unprefixing with lambda replacement" do
    result =
      EnvHelp::Get::var_collection :ROBOCOP_PRIME_DIRECTIVES_, TEST_ENV,
      :un_prefix_keys, lambda{|s| s.to_s.sub('Serve', 'Abuse').sub('Protect', 'Take advantage of').sub('Uphold', 'Break')}
    expect(result).to eq({
      :DIRECTIVE_1=>"Abuse the public trust",
      :DIRECTIVE_2=>"Take advantage of the innocent",
      :DIRECTIVE_3=>"Break the law"
      })
  end

  it "allows nonsensical lambda key modifications" do
    result =
      EnvHelp::Get::var_collection :ABC_, TEST_ENV,
        :un_prefix_keys, :downcase_keys, :mod_keys, lambda {|k| k.to_s.gsub('_','/')},
        :split_to_array, lambda {|vs| vs.map(&:to_i)}
    expect(result).to eq({
      "a/xx/y"=>[0, 1, 2, 3, 4],
      "b/ww/z"=>[5, 6, 7, 8, 9]
      })
  end

  it "allows boolean replacement" do
    result =
      EnvHelp::Get::var_collection :vanguard_mode_, TEST_ENV, :un_prefix_keys, :to_bool_with_fallback, false, lambda{|b| b ? "Yes commander" : "Negative, captain"}

    expect(result).to eq({
      :destroy=>"Yes commander",
      :spy=>"Negative, captain",
      :obliterate=>"Yes commander",
      :cover_my_tracks=>"Yes commander",
      :love_the_world=>"Negative, captain"}
    )
  end

  it "allows conditional numeric conversions" do
    result =
      EnvHelp::Get::var :a, TEST_ENV, :to_i_or=, 3, :if_satisfies, lambda{|x| x > -4}, :or=, 9, lambda{|x| "forget you I don't do what you t#{x}ll me"}
    expect(result).to eq("forget you I don't do what you t1ll me")
  end

  it "detects correct boolean (truthy)" do
    result =
      EnvHelp::Get::var :vanguard_mode_destroy, TEST_ENV, :false_unless_true_ish
    expect(result).to eq(true)
  end

  it "falls back to correct boolean (falsy)" do
    result =
      EnvHelp::Get::var :a, TEST_ENV, :false_unless_true_ish
    expect(result).to eq(false)
  end

  it "detects correct boolean (falsy)" do
    result =
      EnvHelp::Get::var :vanguard_mode_spy, TEST_ENV, :true_unless_false_ish
    expect(result).to eq(false)
  end

  it "falls back to correct boolean (truthy)" do
    result =
      EnvHelp::Get::var :a, TEST_ENV, :true_unless_false_ish
    expect(result).to eq(true)
  end


  it "returns a connection hash" do
    pending("Non-activesupport fallback")
    result =
      EnvHelp::Get::var :db2, TEST_ENV, :connection_config
    expect(result).to eq([1, 2, 3, 4, 5, 6, 7, 8, 9, 0, :you_lose, 0, 5, 0])
  end
  # def numbery(TEST_ENV, *args)
  #   EnvHelp::Get::var :a, TEST_ENV, :to_i_or=, 3, :if_satisfies, lambda{|x| x > -4}, :or=, 9, lambda{|x| "forget you I don't do what you t#{x}ll me"}
  # end

  # it "uses fallback when specified and TEST_ENV not present" do
  #   result =
  #     EnvHelp::Get::var :a, TEST_ENV,
  #       :rangey_or=, -1..16, :in, 0..12, :or=, :you_lose
  #   expect(result).to eq([1, 2, 3, 4, 5, 6, 7, 8, 9, 0, :you_lose, 0, 5, 0])
  # end



  # it "allows conversion from boolean collection to numeric collection" do
  #   result =
  #     EnvHelp::Get::var_collection :vanguard_mode_, TEST_ENV, :un_prefix_keys,
  #     :to_bool_with_fallback, false, :to_i_or=, -666
  #   expect(result).to eq("I'm not even an interesting value")
  # end


end