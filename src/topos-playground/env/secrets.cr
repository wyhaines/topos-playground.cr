require "../env"

class ToposPlayground
  struct Env::Secrets < Env
    def path
      "WORKINGDIR/.env"
    end

    def content
      <<-EENV
      export PRIVATE_KEY=0xd7e2e00b43c12cf17239d4755ed744df6ca70a933fc7c8bbb7da1342a5ff2e38
      export TOKEN_DEPLOYER_SALT=m1Ln9uF9MGZ2PcR
      export TOPOS_CORE_SALT=dCyN8VZz5sXgqMO
      export TOPOS_CORE_PROXY_SALT=aRV8Mp9o4xRpLbF
      export ERC20_MESSAGING_SALT=ho37cJbGkgI6vnp
      export SUBNET_REGISTRATOR_SALT=azsRlXyGu0ty291
      export AUTH0_CLIENT_ID=xVF6EuPDaazQchfjFpGAdcJUpHk2W5I2
      export AUTH0_CLIENT_SECRET=-CrwnrgSx1EaP_oaKAFXFdqrIvA4WK8Pcpd5xC4o3ZfYB4H4V4FPHfEbqpu4KZN8
      EENV
    end
  end
end