require "../env"

class ToposPlayground
  struct Env::DappFrontend < Env
    def path
      "WORKINGDIR/dapp-frontend-erc20-messaging/packages/frontend/.env"
    end

    def content
      <<-EENV.gsub(/\$(\w+)/) { |var| ENV[var]?.to_s }
      VITE_EXECUTOR_SERVICE_ENDPOINT=http://localhost:3000
      VITE_TOPOS_SUBNET_ENDPOINT=localhost:10002
      VITE_TRACING_OTEL_COLLECTOR_ENDPOINT=https://otel-collector.telemetry.devnet-1.topos.technology/v1/traces
      VITE_TRACING_SERVICE_NAME=cross-subnet-message
      VITE_TRACING_SERVICE_VERSION=0.1.0
      
      # Addresses
      VITE_TOPOS_CORE_PROXY_CONTRACT_ADDRESS=$TOPOS_CORE_PROXY_CONTRACT_ADDRESS
      VITE_ERC20_MESSAGING_CONTRACT_ADDRESS=$ERC20_MESSAGING_CONTRACT_ADDRESS
      VITE_SUBNET_REGISTRATOR_CONTRACT_ADDRESS=$SUBNET_REGISTRATOR_CONTRACT_ADDRESS

      EENV
    end
  end
end
