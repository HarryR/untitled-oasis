# SPDX-License-Identifier: Apache-2.0

SAPPHIRE_DOCKER=ghcr.io/oasisprotocol/sapphire-localnet:latest

all build test test-localnet:
	make -C contracts-proxy $@
	make -C contracts-messaging $@
	make -C contracts-bridge-example $@

################################################################################
# Run Oasis Sapphire localnet node

sapphire-localnet: observer-localnet
	docker run --rm -ti -p8544-8548:8544-8548 $(SAPPHIRE_DOCKER)

sapphire-localnet-pull:
	docker pull $(SAPPHIRE_DOCKER)
