require "../env"

class ToposPlayground
  struct Env::Secrets < Env
    KeyHash = {
      "PRIVATE_KEY"             => "0xd7e2e00b43c12cf17239d4755ed744df6ca70a933fc7c8bbb7da1342a5ff2e38",
      "TOKEN_DEPLOYER_SALT"     => "m1Ln9uF9MGZ2PcR",
      "TOPOS_CORE_SALT"         => "dCyN8VZz5sXgqMO",
      "TOPOS_CORE_PROXY_SALT"   => "aRV8Mp9o4xRpLbF",
      "ERC20_MESSAGING_SALT"    => "ho37cJbGkgI6vnp",
      "SUBNET_REGISTRATOR_SALT" => "azsRlXyGu0ty291",
      "AUTH0_CLIENT_ID"         => "xVF6EuPDaazQchfjFpGAdcJUpHk2W5I2",
      "AUTH0_CLIENT_SECRET"     => "-CrwnrgSx1EaP_oaKAFXFdqrIvA4WK8Pcpd5xC4o3ZfYB4H4V4FPHfEbqpu4KZN8",
    }

    def path
      "WORKINGDIR/.env.secrets"
    end

    def content
      String.build do |str|
        KeyHash.each do |key, value|
          str << "export #{key}=#{value}\n"
        end
      end
    end

    def env(env = ENV.dup)
      merge_env(KeyHash, env)
    end
  end
end
