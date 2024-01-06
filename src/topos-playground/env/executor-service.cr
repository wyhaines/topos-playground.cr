require "../env"

class ToposPlayground
  struct Env::ExecutorService < Env
    def path
      "WORKINGDIR/executor-service/.env"
    end

    def content
      <<-EENV
      AUTH0_AUDIENCE=https://executor.demo.toposware.com
      AUTH0_ISSUER_URL=https://dev-z8x4rhzfosi03fqx.us.auth0.com/
      REDIS_HOST=localhost
      REDIS_PORT=6379
      TOPOS_SUBNET_ENDPOINT_WS=ws://localhost:10002/ws


      EENV
    end
  end
end
