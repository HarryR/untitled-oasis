ARTIFACTS_DIR=../../artifacts/unstable

.PHONY: all compile build test clean copy-artifacts

all: build test copy-artifacts

compile build:
	pnpm hardhat compile --force

copy-artifacts: $(ARTIFACTS_DIR)/ValidatorSet.json \
				$(ARTIFACTS_DIR)/MessageEmitterV1.json \
				$(ARTIFACTS_DIR)/MessageDecoderV1.json \
				$(ARTIFACTS_DIR)/IAllowedSigner.json \
				$(ARTIFACTS_DIR)/IEmitter.json \
				$(ARTIFACTS_DIR)/SignatureCollector.json

$(ARTIFACTS_DIR)/%.json: artifacts/build-info
	mkdir -p $(ARTIFACTS_DIR)
	cp "artifacts/contracts/$*.sol/$*.json" "$@"

test:
	pnpm hardhat test

clean:
	rm -rf artifacts cache typechain-generated typechain-ethers-v6
