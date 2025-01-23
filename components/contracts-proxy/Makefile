.PHONY: all compile build test test-localnet

all: compile test

compile build:
	pnpm hardhat compile --force

test:
	pnpm hardhat test

test-localnet:
	pnpm hardhat test --network sapphire-localnet
