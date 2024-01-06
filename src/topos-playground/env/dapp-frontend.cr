require "../env"

class ToposPlayground
  struct Env::DappFrontend < Env
    def path
      "WORKINGDIR/dapp-frontend-erc20-messaging/packages/frontend/.env"
    end

    def content
      <<-EENV.gsub(/\$(\w+)/) { |var| ENV[var]?.to_s }
      VITE_EXECUTOR_SERVICE_ENDPOINT=http://localhost:3000
      VITE_TOPOS_SUBNET_ENDPOINT_HTTP=http://localhost:10002
      VITE_TOPOS_SUBNET_ENDPOINT_WS=ws://localhost:10002/ws
      VITE_OTEL_EXPORTER_OTLP_ENDPOINT=http://example.com
      VITE_OTEL_SERVICE_NAME=dapp-frontend-erc20-messaging
      VITE_OTEL_SERVICE_VERSION=topos-playground

      # Addresses
      VITE_TOPOS_CORE_PROXY_CONTRACT_ADDRESS=$TOPOS_CORE_PROXY_CONTRACT_ADDRESS
      VITE_ERC20_MESSAGING_CONTRACT_ADDRESS=$ERC20_MESSAGING_CONTRACT_ADDRESS
      VITE_SUBNET_REGISTRATOR_CONTRACT_ADDRESS=$SUBNET_REGISTRATOR_CONTRACT_ADDRESS


      EENV
    end
  end
end
