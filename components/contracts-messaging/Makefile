ARTIFACTS_DIR=../../artifacts/unstable

.PHONY: all compile build clean test-localnet test clean copy-artifacts

all: build test copy-artifacts

BUILDINFO_OUT=$(ARTIFACTS_DIR)/contracts-messaging.build-info

copy-artifacts: $(ARTIFACTS_DIR)/ValidatorSet.json \
				$(ARTIFACTS_DIR)/MessageEmitterV1.json \
				$(ARTIFACTS_DIR)/MessageDecoderV1.json \
				$(ARTIFACTS_DIR)/IAllowedSigner.json \
				$(ARTIFACTS_DIR)/IEmitter.json \
				$(ARTIFACTS_DIR)/SignatureCollector.json
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
