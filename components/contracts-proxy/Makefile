ARTIFACTS_DIR=../../artifacts/unstable

.PHONY: all compile build test test-localnet copy-artifacts

all: compile test copy-artifacts

copy-artifacts: $(ARTIFACTS_DIR)/AtomicProxyFactory.json

$(ARTIFACTS_DIR)/%.json: artifacts/build-info
	mkdir -p $(ARTIFACTS_DIR)
	cp "artifacts/contracts/$*.sol/$*.json" "$@"

compile build:
	pnpm hardhat compile --force

test:
	pnpm hardhat test

test-localnet:
	pnpm hardhat test --network sapphire-localnet
