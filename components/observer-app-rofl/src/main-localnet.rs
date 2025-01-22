// SPDX-License-Identifier: Apache-2.0

#![cfg(all(feature="observer-localnet", feature="debug-mock-sgx"))]

fn main () {
    observer_app_rofl::observer_main();
}
