Please note, here are 'unstable' artifacts generated from the Hardhat Solidity
build process. They are necessary for the Rust build process and thus are
committed to the repo.

When various Solidity components are released, they will be copied to e.g.

    artifacts/component-1.2.3

This includes both the ABI and bytecode, but also the full build info (gzipped),
this is necessary to verify contracts on-chain.
