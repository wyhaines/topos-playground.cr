require "./spec_helper"

describe ToposPlayground::CommandRegistry do
  it "registers the expected command names" do
    ["clean", "start"].each do |command_name|
      ToposPlayground::CommandRegistry.names.includes?(command_name).should be_true
    end
  end

  it "can fetch a specific env type, by name" do
    ToposPlayground::CommandRegistry["start"].should be_a ToposPlayground::Command::Start.class
  end
end
