ARTIFACTS_DIR=../../artifacts/unstable

.PHONY: all solidity compile build test clean copy-artifacts

all: build test copy-artifacts

copy-artifacts: $(ARTIFACTS_DIR)/BridgeOnRemote.json \
				$(ARTIFACTS_DIR)/BridgeOnSapphire.json \
				$(ARTIFACTS_DIR)/BridgeToken.json

$(ARTIFACTS_DIR)/%.json: artifacts/build-info
	mkdir -p $(ARTIFACTS_DIR)
	cp "artifacts/contracts/$*.sol/$*.json" "$@"

compile build solidity:
	pnpm hardhat compile --force

test:
	pnpm hardhat test

clean:
	rm -rf artifacts cache typechain-generated typechain-ethers-v6
