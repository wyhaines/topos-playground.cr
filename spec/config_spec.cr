require "./spec_helper"

describe ToposPlayground::Config do
  it "can access the raw data structure from the config" do
    config = ToposPlayground::Config.new
    config.data.should be_a Hash(String, ToposPlayground::Config::ConfigTypes)
  end

  it "can assign values to a configuration via method-call syntax" do
    config = ToposPlayground::Config.new
    config.foo = "bar"
    config.bif = "baz"
    config.true = true
    config.onetwothree = 123

    config.data["foo"].should eq "bar"
    config.data["bif"].should eq "baz"
    config.data["true"].should eq true
    config.data["onetwothree"].should eq 123
  end

  it "can retrieve values from a configuration via method-call syntax" do
    config = ToposPlayground::Config.new
    config["foo"] = "bar"
    config["bif"] = "baz"
    config["true"] = true
    config["onetwothree"] = 123

    config.foo.should eq "bar"
    config.bif.should eq "baz"
    config.true.should be_true
    config.onetwothree.should eq 123
  end

  it "can set and retrieve values from a configuration via method-call syntax" do
    config = ToposPlayground::Config.new
    config.foo = "bar"
    config["bif"] = "baz"
    config.true = true
    config["onetwothree"] = 123

    config.foo.should eq "bar"
    config["bif"].should eq "baz"
    config.true.should be_true
    config["onetwothree"].should eq 123
  end

  it "nilable queries work correctly" do
    config = ToposPlayground::Config.new
    config.defined_value = true

    config.defined_value?.should be_true
    config.undefined_value?.should be_falsey
  end
end
