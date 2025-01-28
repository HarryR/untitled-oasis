.PHONY: all solidity compile build test clean

all: build test

compile build solidity:
	pnpm hardhat compile --force

test:
	pnpm hardhat test

clean:
	rm -rf artifacts cache typechain-generated typechain-ethers-v6
