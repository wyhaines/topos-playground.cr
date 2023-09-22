require "../env"

class ToposPlayground
  struct Env::DappBackend < Env
    def path
      "WORKINGDIR/dapp-frontend-erc20-messaging/packages/backend/.env"
    end

    def content
      <<-EENV
      PORT=3001
      AUTH0_AUDIENCE=https://executor.demo.toposware.com
      AUTH0_ISSUER_URL=https://dev-z8x4rhzfosi03fqx.us.auth0.com

      EENV
    end
  end
end
