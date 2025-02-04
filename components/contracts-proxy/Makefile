ARTIFACTS_DIR=../../artifacts/unstable

.PHONY: all compile build clean test test-localnet copy-artifacts

all: compile test copy-artifacts

BUILDINFO_OUT=$(ARTIFACTS_DIR)/contracts-proxy.build-info

copy-artifacts: $(ARTIFACTS_DIR)/AtomicProxyFactory.json
	rm -f $(BUILDINFO_OUT).gz
	cp artifacts/build-info/*.json $(BUILDINFO_OUT)
	gzip -9 $(BUILDINFO_OUT)

$(ARTIFACTS_DIR)/%.json: artifacts/build-info
	mkdir -p $(ARTIFACTS_DIR)
	cp "artifacts/contracts/$*.sol/$*.json" "$@"

compile build solidity:
	pnpm hardhat compile --force

test:
	pnpm hardhat test

test-localnet:
	pnpm hardhat test --network sapphire-localnet

clean:
	rm -rf artifacts cache typechain-ethers-v6
