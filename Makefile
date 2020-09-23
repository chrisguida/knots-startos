ASSETS := $(shell yq r manifest.yaml assets.*.src)
ASSET_PATHS := $(addprefix assets/,$(ASSETS))
VERSION := $(shell yq r manifest.yaml version)
MANAGER_SRC := $(shell find ./manager -name '*.rs')

.DELETE_ON_ERROR:

all: bitcoind.s9pk

bitcoind.s9pk: manifest.yaml config_spec.yaml config_rules.yaml image.tar $(ASSET_PATHS)
	appmgr -vv pack $(shell pwd) -o bitcoind.s9pk
	appmgr verify bitcoind.s9pk

image.tar: Dockerfile docker_entrypoint.sh manager/target/armv7-unknown-linux-musleabihf/release/bitcoind-manager
	test $(shell uname -m) -eq "aarch64"
	docker build -t start9/bitcoind --build-arg BITCOIN_VERSION=$(VERSION) .
	docker save start9/bitcoind > image.tar
	docker rmi start9/bitcoind

manager/target/armv7-unknown-linux-musleabihf/release/bitcoind-manager: $(MANAGER_SRC)
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/manager:/home/rust/src start9/rust-musl-cross:armv7-musleabihf cargo build --release
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/manager:/home/rust/src start9/rust-musl-cross:armv7-musleabihf musl-strip target/armv7-unknown-linux-musleabihf/release/bitcoind-manager
