require "./spec_helper"
require "../src/topos-playground/env/*"

describe ToposPlayground::EnvRegistry do
  it "registers the expected env names" do
    ["dappbackend", "dappfrontend", "executorservice", "secrets"].each do |env_name|
      ToposPlayground::EnvRegistry.names.includes?(env_name).should be_true
    end
  end

  it "can fetch a specific env type, by name" do
    ToposPlayground::EnvRegistry["secrets"].should be_a ToposPlayground::Env::Secrets.class
  end
end
