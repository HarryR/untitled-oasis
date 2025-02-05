# SPDX-License-Identifier: Apache-2.0

ENVIRONMENTS=localnet testnet mainnet

all: debug

debug: build-debug observer-debug

release: build-release observer-release

build-debug:
	cargo build

build-release:
	cargo build -r

clean clippy:
	cargo $@

observer-release-app-%:
	cargo build -F observer-$* -r --bin observer-app-$*

observer-debug-app-%:
	cargo build -F observer-$* --bin observer-app-$*

observer-release: $(ENVIRONMENTS:%=observer-release-app-%)

observer-debug: $(ENVIRONMENTS:%=observer-debug-app-%)
