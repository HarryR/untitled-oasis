# SPDX-License-Identifier: Apache-2.0

PNPM = pnpm

PYTHON = python3

OASIS_CLI_VERSION=0.10.4
OASIS_CLI_ARCH=linux_amd64
OASIS_CLI_DIR=oasis_cli_$(OASIS_CLI_VERSION)_$(OASIS_CLI_ARCH)
OASIS_CLI_FILENAME=$(OASIS_CLI_DIR).tar.gz
OASIS_CLI_URL=https://github.com/oasisprotocol/cli/releases/download/v$(OASIS_CLI_VERSION)/$(OASIS_CLI_FILENAME)

SGX_HEAP=0x20000000 # 512mb
SGX_STACK=0x200000  # 2mb
SGX_THREADS=32
SGX_TARGET=x86_64-fortanix-unknown-sgx
CARGO_BUID_SGX=cargo build --target $(SGX_TARGET)
FTXSGX=ftxsgx-elf2sgxs --heap-size $(SGX_HEAP) --stack-size $(SGX_STACK) --threads $(SGX_THREADS)

OASIS_ORC_TOOL=go run github.com/oasisprotocol/oasis-sdk/tools/orc@latest

APP_ROFL_VERSION=$(shell cargo pkgid -p observer-app-rofl | cut '-d#' -f2)

SAPPHIRE_DOCKER=ghcr.io/oasisprotocol/sapphire-localnet:latest

################################################################################

all:
	@echo $(APP_ROFL_VERSION)

################################################################################

bin/$(OASIS_CLI_FILENAME):
	wget -O "$@" "$(OASIS_CLI_URL)"

bin/$(OASIS_CLI_DIR): bin/$(OASIS_CLI_FILENAME)
	tar -C bin -xf "$(OASIS_CLI_FILENAME)"

oasis: bin/$(OASIS_CLI_DIR)

################################################################################

solidity:
	make -C components/contracts-proxy
	make -C components/contracts-messaging
	make -C components/contracts-bridge-example

################################################################################

clean-cargo:
	cargo clean
	rm -rf target

clean-solidity:
	rm -rf artifacts cache typechain-generated

clean: clean-cargo clean-solidity

distclean: clean
	rm -rf "$(OASIS_CLI_DIR)" "$(OASIS_CLI_FILENAME)"
	rm -rf node_modules

################################################################################

.signing/testnet.pem:
	mkdir -p .signing
	openssl genrsa -3 3072 > "$@"

.signing/mainnet.pem:
	mkdir -p .signing
	openssl genrsa -3 3072 > "$@"

################################################################################
# Run Sapphire + ROFL, with debugging / logging

sapphire-localnet: observer-localnet
	mkdir -p rofls
	cp $(OBSERVER_APP_ROFL_LOCALNET).orc rofls
	docker run --rm -ti -p8544-8548:8544-8548 --mount type=bind,readonly,src=`pwd`/rofls,dst=/rofls $(SAPPHIRE_DOCKER)

sapphire-localnet-pull:
	docker pull $(SAPPHIRE_DOCKER)

rofl-logs:
	docker exec $(shell docker ps --format json | jq -rc 'select(.Image|test("sapphire-localnet")) | .Names') bash -c 'tail -f /serverdir/node/net-runner/network/compute-0/node.log' | jq -rc 'select(.component == "rofl") | .component + " " + (.ts | split(".") | .[0] ) + " " + .msg'

################################################################################

observer: observer-mock observer-localnet observer-testnet observer-mainnet

################################################################################
# mock observer

OBSERVER_APP_MOCK=target/debug/observer-app-mock
$(OBSERVER_APP_MOCK):
	cargo build -F observer-mock --bin observer-app-mock

observer-mock: $(OBSERVER_APP_MOCK)

################################################################################
# localnet observer

OBSERVER_APP_ROFL_LOCALNET=target/x86_64-unknown-linux-gnu/debug/observer-app-rofl-localnet

.PRECIOUS: $(OBSERVER_APP_ROFL_LOCALNET)

$(OBSERVER_APP_ROFL_LOCALNET): components/observer-app-rofl/Cargo.toml
	OASIS_UNSAFE_MOCK_SGX=1 OASIS_UNSAFE_ALLOW_DEBUG_ENCLAVES=1 OASIS_UNSAFE_SKIP_AVR_VERIFY=1 cargo build --target x86_64-unknown-linux-gnu -F observer-localnet,debug-mock-sgx --bin observer-app-rofl-localnet

$(OBSERVER_APP_ROFL_LOCALNET).orc: $(OBSERVER_APP_ROFL_LOCALNET)
	$(PYTHON) bin/build-rofl-orc.py --out "$@" --version $(APP_ROFL_VERSION) --name observer --runtime sapphire-localnet --elf $<

observer-localnet: $(OBSERVER_APP_ROFL_LOCALNET).orc
	$(OASIS_ORC_TOOL) show $<

################################################################################
# testnet observer

OBSERVER_APP_ROFL_TESTNET=target/$(SGX_TARGET)/release/observer-app-rofl-testnet

.PRECIOUS: $(OBSERVER_APP_ROFL_TESTNET)
.PRECIOUS: $(OBSERVER_APP_ROFL_TESTNET).sig
.PRECIOUS: $(OBSERVER_APP_ROFL_TESTNET).sgxs

$(OBSERVER_APP_ROFL_TESTNET): components/observer-app-rofl/Cargo.toml
	$(CARGO_BUID_SGX) -F observer-testnet -r --bin observer-app-rofl-testnet

$(OBSERVER_APP_ROFL_TESTNET).sgxs: $(OBSERVER_APP_ROFL_TESTNET)
	$(FTXSGX) $< --output $@

$(OBSERVER_APP_ROFL_TESTNET).sig: $(OBSERVER_APP_ROFL_TESTNET).sgxs .signing/testnet.pem
	sgxs-sign --key .signing/testnet.pem $(OBSERVER_APP_ROFL_TESTNET).sgxs $(OBSERVER_APP_ROFL_TESTNET).sig --xfrm 7/0 --isvprodid 0 --isvsvn 0

$(OBSERVER_APP_ROFL_TESTNET).orc: $(OBSERVER_APP_ROFL_TESTNET).sig
	$(PYTHON) build-rofl-orc.py --out "$@" --version $(APP_ROFL_VERSION) --name observer --runtime sapphire-testnet --elf $(OBSERVER_APP_ROFL_TESTNET) --sgxs $(OBSERVER_APP_ROFL_TESTNET).sgxs --sig $(OBSERVER_APP_ROFL_TESTNET).sig

observer-testnet: $(OBSERVER_APP_ROFL_TESTNET).orc
	$(OASIS_ORC_TOOL) show $<

################################################################################
# mainnet observer

OBSERVER_APP_ROFL_MAINNET=target/$(SGX_TARGET)/release/observer-app-rofl-mainnet

.PRECIOUS: $(OBSERVER_APP_ROFL_MAINNET)
.PRECIOUS: $(OBSERVER_APP_ROFL_MAINNET).sig
.PRECIOUS: $(OBSERVER_APP_ROFL_MAINNET).sgxs

$(OBSERVER_APP_ROFL_MAINNET): components/observer-app-rofl/Cargo.toml
	$(CARGO_BUID_SGX) -F observer-mainnet -r --bin observer-app-rofl-mainnet

$(OBSERVER_APP_ROFL_MAINNET).sgxs: $(OBSERVER_APP_ROFL_MAINNET)
	$(FTXSGX) $< --output $@

$(OBSERVER_APP_ROFL_MAINNET).sig: $(OBSERVER_APP_ROFL_MAINNET).sgxs .signing/mainnet.pem
	sgxs-sign --key .signing/mainnet.pem $(OBSERVER_APP_ROFL_MAINNET).sgxs $(OBSERVER_APP_ROFL_MAINNET).sig --xfrm 7/0 --isvprodid 0 --isvsvn 0

$(OBSERVER_APP_ROFL_MAINNET).orc: $(OBSERVER_APP_ROFL_MAINNET).sig
	$(PYTHON) build-rofl-orc.py --out "$@" --version $(APP_ROFL_VERSION) --name observer --runtime sapphire-mainnet --elf $(OBSERVER_APP_ROFL_MAINNET) --sgxs $(OBSERVER_APP_ROFL_MAINNET).sgxs --sig $(OBSERVER_APP_ROFL_MAINNET).sig

observer-mainnet: $(OBSERVER_APP_ROFL_MAINNET).orc
	$(OASIS_ORC_TOOL) show $<

################################################################################
