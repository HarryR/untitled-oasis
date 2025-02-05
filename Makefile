# SPDX-License-Identifier: Apache-2.0

all: solidity rust

solidity rust:
	make -C components/$@

rust-%:
	make -C components/rust $*

solidity-%:
	make -C components/solidity $*

clean: rust-clean solidity-clean

distclean: clean rust-distclean solidity-distclean
	rm -rf node_modules
