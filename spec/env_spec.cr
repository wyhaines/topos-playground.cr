require "./spec_helper"
require "../src/topos-playground/env/*"

describe ToposPlayground::Env do
  it "subclasses return a path" do
    [
      ToposPlayground::Env::Secrets,
      ToposPlayground::Env::ExecutorService,
      ToposPlayground::Env::DappFrontend,
      ToposPlayground::Env::DappBackend,
    ].each do |env_class|
      env_class.new.path.should be_a String
      env_class.new.path.should contain "WORKINGDIR"
    end
  end

  it "subclasses return content" do
    [
      ToposPlayground::Env::Secrets,
      ToposPlayground::Env::ExecutorService,
      ToposPlayground::Env::DappFrontend,
      ToposPlayground::Env::DappBackend,
    ].each do |env_class|
      env_class.new.content.should be_a String
      env_class.new.content.should contain "="
    end
  end

  it "ToposPlayground::Env::Secrets.env returns a hash" do
    ToposPlayground::Env::Secrets.new.env.should be_a Process::Env
  end
end
