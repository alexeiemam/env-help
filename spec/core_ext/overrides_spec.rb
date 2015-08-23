require "spec_helper"

RSpec.describe Object do
  it "offers activesupport-like 'try' support when activesupport not present" do
    string = "abv"
    non_string = 2
    expect(string.try(:upcase)).to eq("ABV")
    expect(non_string.try(:upcase)).to eq(nil)

    blocked_result_arity = 
      string.try do |v|
        v
      end

    blocked_result = 
      string.try do
        'chickens'
      end

    expect(blocked_result_arity).to eq(string)
    expect(blocked_result).to eq('chickens')
  end

  it "offers activesupport-like 'present?', 'presence', 'blank?' support when activesupport not present" do
    there = 'i_am_here'
    not_there = []
    expect(there.presence).to eq(there)
    expect(there.present?).to eq(true)
    expect(there.blank?).to eq(false)
    expect(not_there.presence).to eq(nil)
    expect(not_there.present?).to eq(false)
    expect(not_there.blank?).to eq(true)
  end

  it "offers activesupport-like 'in?' support when activesupport not present" do
    the_one = 'jose'
    c_staff = %w( 
      roman
      jose
    )

    a_staff = %w(
      arsene
      kroenke
    )

    bork_staff = 2
    expect(the_one.in?(c_staff)).to eq(true)
    expect(the_one.presence_in(c_staff)).to eq(the_one)
    expect(the_one.presence_in(a_staff)).to eq(nil)
    expect(the_one.in?(a_staff)).to eq(false)
    expect {the_one.in?(bork_staff)}.to raise_error(ArgumentError)
  end

  it "offers activesupport-like 'starts_with?, ends_with?' support when activesupport not present" do
    string = 'very_big_dog'
    expect(string.starts_with?('very')).to eq(true)
    expect(string.ends_with?('dog')).to eq(true)

    expect(string.starts_with?('big')).to eq(false)
    expect(string.ends_with?('big')).to eq(false)
  end

  it "offers activesupport-like 'String.last, String.from' support when activesupport not present" do
    string = 'irate_platypus'
    expect(string.last(8)).to eq('platypus')
    expect(string.last(0)).to eq('')
    expect(string.last(200)).to eq(string)
    expect(string.from(6)).to eq('platypus')
  end
end