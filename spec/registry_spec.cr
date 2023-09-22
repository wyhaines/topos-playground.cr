require "./spec_helper"
require "../src/topos-playground/registry"

abstract class TestRegistee
  macro inherited
    TestRegistry.register self
  end

  def name
    self.class.name
  end
end

class TestRegistry < ToposPlayground::Registry
  @@name_to_class_map = {} of String => TestRegistee.class
end

class TestRegisteeA < TestRegistee; end

class TestRegisteeB < TestRegistee; end

class TestRegisteeC < TestRegistee; end

describe ToposPlayground::Env do
  it "can fetch the registry object" do
    TestRegistry.registry.should be_a Hash(String, TestRegistee.class)
  end

  it "can get a list of the names of all registered classes" do
    [
      "testregisteea",
      "testregisteeb",
      "testregisteec",
    ].each do |name|
      TestRegistry.names.includes?(name).should be_true
    end
  end

  it "can get a lit of the registered classes themselves" do
    [
      TestRegisteeA,
      TestRegisteeB,
      TestRegisteeC,
    ].each do |klass|
      TestRegistry.classes.includes?(klass).should be_true
    end
  end

  it "can access a class by name" do
    TestRegistry["testregisteea"].should eq TestRegisteeA
    TestRegistry.get("testregisteea").should eq TestRegisteeA
    TestRegistry["testregisteeb"].should eq TestRegisteeB
    TestRegistry.get("testregisteeb").should eq TestRegisteeB
    TestRegistry["testregisteec"].should eq TestRegisteeC
    TestRegistry.get("testregisteec").should eq TestRegisteeC
  end

  it "can be used to explicitly set a name to a class" do
    TestRegistry["alsoa"] = TestRegisteeA
    TestRegistry.get("alsoa").should eq TestRegisteeA
    TestRegistry.set("alsob", TestRegisteeB)
    TestRegistry.get("alsob").should eq TestRegisteeB

    TestRegistry.registry.delete("testregisteec")
    TestRegistry.register(TestRegisteeC)
    TestRegistry["testregisteec"].should eq TestRegisteeC
  end
end
