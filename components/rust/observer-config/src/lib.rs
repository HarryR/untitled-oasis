// SPDX-License-Identifier: Apache-2.0

use clap::ValueEnum;

#[derive(Debug, Clone, Copy, ValueEnum)]
pub enum NetworkMode {
    Localnet,
    Testnet,
    Mainnet,
}

pub fn network_mode() -> NetworkMode {
    if cfg!(feature = "observer-localnet") {
        NetworkMode::Localnet
    }
    else if cfg!(feature = "observer-testnet") {
        NetworkMode::Testnet
    }
    else if cfg!(feature = "observer-mainnet") {
        NetworkMode::Mainnet
    }
    else {
        panic!("Unknown network");
    }
}

#[derive(Debug)]
pub struct ObserverConfig {
    pub mode: NetworkMode
}

impl ObserverConfig {
    pub fn from_mode(mode: NetworkMode) -> Self {
        match mode {
            NetworkMode::Localnet => Self {
                mode
            },
            NetworkMode::Testnet => Self {
                mode
            },
            NetworkMode::Mainnet => Self {
                mode
            },
        }
    }

    pub fn new() -> Self {
        Self::from_mode(network_mode())
    }
}

impl Default for ObserverConfig {
    fn default() -> Self {
        Self::new()
    }
}
