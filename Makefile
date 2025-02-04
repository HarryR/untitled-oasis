# SPDX-License-Identifier: Apache-2.0

PNPM = pnpm

PYTHON = python3

SAPPHIRE_DOCKER=ghcr.io/oasisprotocol/sapphire-localnet:latest

################################################################################

all:
	@echo $(APP_ROFL_VERSION)

################################################################################

solidity-%:
	make -C components/contracts-proxy $*
	make -C components/contracts-messaging $*
	make -C components/contracts-bridge-example $*

solidity: solidity-all

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
# Run Oasis Sapphire

sapphire-localnet: observer-localnet
	docker run --rm -ti -p8544-8548:8544-8548 $(SAPPHIRE_DOCKER)

sapphire-localnet-pull:
	docker pull $(SAPPHIRE_DOCKER)

################################################################################

observer: observer-mock

OBSERVER_APP_MOCK=target/debug/observer-app-mock
$(OBSERVER_APP_MOCK):
	cargo build -F observer-mock --bin observer-app-mock

OBSERVER_APP_LOCALNET=target/debug/observer-app-localnet
$(OBSERVER_APP_LOCALNET):
	cargo build -F observer-localnet --bin observer-app-localnet

OBSERVER_APP_TESTNET=target/debug/observer-app-testnet
$(OBSERVER_APP_TESTNET):
	cargo build -F observer-testnet --bin observer-app-testnet

OBSERVER_APP_MAINNET=target/debug/observer-app-mainnet
$(OBSERVER_APP_MAINNET):
	cargo build -F observer-mainnet --bin observer-app-mainnet

observer-mock:  $(OBSERVER_APP_MOCK) \
				$(OBSERVER_APP_LOCALNET) \
				$(OBSERVER_APP_TESTNET) \
				$(OBSERVER_APP_MAINNET)
