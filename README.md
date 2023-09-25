<div id="top" />
<br />
<div align="center">
  <img src="https://raw.githubusercontent.com/topos-protocol/topos-playground/main/.github/assets/topos_logo_dark.png#gh-dark-mode-only" alt="Logo" width="200">
  <br />
  <p align="center">
  <b>Topos Playground</b> is a CLI (command-line interface) to run a local Topos devnet 🚀
  </p>
  <p>
  This version in an unofficial version inspired by <a href="https://github.com/topos-protocol/topos-playground">the official version of topos-playground</a>. This version should have feature-parity with the official version, and may have additional features. This version is also distributed as a standalone binary instead of a Node.js application.
  </p>
  <br />
</div>

## Getting Started

The Topos Playground is a CLI that allows you to easily run and manage a local Topos devnet. The components that it runs on your behalf depend on Docker, Docker Compose, and NodeJS to locally run multiple subnets, multiple TCE nodes, and a dApp with supporting infrastructure, capable of cross-subnet messaging. For official documentation about Topos and about the official Playground CLI, take a look at the [Topos Developer Portal](https://docs.topos.technology).

### Requirements

- [Docker](https://docs.docker.com/get-docker/_) version 17.06.0 or greater
- [Docker Compose](https://docs.docker.com/compose/install/) version 2.0.0 or greater
- [NodeJS](https://nodejs.dev/en/) version 16.0.0 or greater
- Git

### Install / Run topos-playground

Precompiled, statically linked binaries are available for Linux and for MacOS from the [Releases](https://github.com/wyhaines/topos-playground.cr/releases) tab in this github repository. Download the appropriate binary for your platform, and uncompress it. You may want to rename it to just `topos-playground`, as all precompiled binaries reflect the architecture and platform that they were compiled for in their names, and you may want to move it into your $PATH:

```
gzip -d topos-playground-linux-x86_64.gz # or `unzip topos-playground-darwin.zip`
mv topos-playground-linux-x86_64 topos-playground`

```

#### Install via Git

If you prefer to install the playground via Git, you can clone the repository and build it manually. This will require that you have [Crystal](https://crystal-lang.org/install/) installed.

```
$ git clone https://github.com/wyhaines/topos-playground.cr.git
$ cd topos-playground.cr
$ shards build --release
```

The compiled `topos-playground` will be placed into `bin/topos-playground`.

### Run the CLI


```
$ topos-playground --help
```

Topos Playground supports two subcommands, `start` and `clean`.

```
$ topos-playground start
```

This will check that the required prerequisites are met, and will then setup and start all of the containers for a complete local Topos network. It will report progress to the console as well as logging to a file.

```
$ topos-playground clean
```

To clean up any still-running docker containers or filesystem artifacts from a previous invocation of the topos-playground, use the `clean` command.

The playground respects XDG Base Directory Specifications, so by default, it will store data used while running in `$HOME/.local/share/topos-playground` and it will store logs in `$HOME/.state/topos-playground/logs`.

To override these default locations, you can set your `HOME`, `XDG_DATA_HOME` and `XDG_STATE_HOME` environment variables, or specify them in a `.env` file.

```
$ HOME=/tmp topos-playground start
```

By default, topos-playground sends output to both your console and to a log file when it is running. To disable this, you can use the `--quiet` flag to prevent output from going to the console, or the `--no-log` flag to prevent output from going to the log file.

```
$ topos-playground clean --quiet
```

For more in-depth discussion about the playground components, and what the `topos-playground` is doing, take a look at the [Topos Playground components](https://docs.topos.technology/content/module-2/3-components.html) portion of the Topos Developer Portal.

### Development

To contribute to the development of this version of the playground, [fork](https://github.com/wyhaines/topos-playground.cr/fork) the repository.

Do your work within a branch on your fork. When it is ready, create a Pull Request that clearly explains the reasoning behind your code changes, what they do, and anything that we should be aware of when testing your code.

i.e.

1. Fork it (<https://github.com/wyhaines/topos-playground/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Discussion

For Topos community help or discussion, you can join the Topos Discord server:

[https://discord.gg/zMCqqCbGMV](https://discord.gg/zMCqqCbGMV)

### Troubleshooting

* `Running the redis server...❗ Error`

The container that provides the Redis service was unable to start. This is likely because you are already running a Redis instance on your system. Try shutting it down.

On Linux:

```
$ sudo systemctl stop redis-server
```

or


```
$ sudo service redis-server stop
```

On MacOS:

```
brew services stop redis
```

If you manually installed and started Redis, you will need to manually stop it.

```
$ redis-cli shutdown
```

* `docker: Error response from daemon: Conflict. The container name "/redis-stack-server" is already in use by container "1ccdeb3adf2259168a5f74697013eaab8d61fb18e123e0a4d06545ac4269cc94". You have to remove (or rename) that container to be able to reuse that name.`

This error indicates that the `redis-stack-server` container is already running. This is likely because you have already ran the playground, but a `topos-playground clean` was never ran. To fix this, run `topos-playground clean` and then try again.

This may also sometimes occur if you have a local redis instance running. Refer to the instructions above for how to shut down a local redis instance.

* `Error: service "contracts-incal" didn't complete successfully: exit 1`

One cause of this error is a previous failure when starting the playground that wasn't cleaned up by running `topos-playground clean`. To fix this, run `topos-playground clean` and then try again.

* `Error: info: unknown shorthand flag: 'd' in -d`

If you see this error, you likely do not have Docker Compose installed. You need version 2 or greater. Refer to the [Docker Compose installation instructions](https://docs.docker.com/compose/install/) for your platform.

* `Error: failed to create network local-erc20-messaging-infra-docker: Error response from daemon: could not find an available, non-overlapping IPv4 address pool among the defaults to assign to the network`

The likely cause of this error is that you are running a VPN of some sort.

The quick fix for this is to shut down your VPN, and then try to run the playground again.

* `Error: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?`

If this error occurs, it likely means that your `dockerd` daemon is not running. Please consult the documentation for your OS and Docker installation to determine how to correctly restart it for your platform.

* `Error: Error response from daemon: driver failed programming external connectivity on endpoint infra-tce-boot-1 (145130455efa244316eb0570064adb584e2c99d18fa2cd8f58b2774f1144d2bb):  (iptables failed: iptables --wait -t nat -A DOCKER -p tcp -d 0/0 --dport 32807 -j DNAT --to-destination 172.21.0.9:9090 ! -i br-de97b637b33b: iptables v1.8.7 (nf_tables): unknown option "--to-destination"`

If this error occurs, you are running Linux, and you have recently done an OS upgrade, try rebooting your system. If the problem persists, first ensure that you can load the 'xt_nat' kernel module:

```
$ sudo modprobe xt_nat
```

If that command fails, then this is likely the problem. You can try to load the module manually:

```
$ sudo insmod /lib/modules/$(uname -r)/kernel/net/netfilter/xt_nat.ko
```

And then try again.

If that command succeeds, but the problem persists, check your iptables version:

```
$ iptables --version
```

It should show something like this:

```
iptables v1.8.7 (nf_tables)
```

If the `nf_tables` is absent, and you have already tried to reboot, investigate your `/usr/sbin/iptables` symlink. It should point to `/usr/sbin/xtables-nft-multi`. It should, either via a direct link, or perhaps through a chain of symlinks, point to `/usr/sbin/xtables-nft-multi`.

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer
