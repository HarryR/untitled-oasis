// SPDX-License-Identifier: Apache-2.0

use oasis_runtime_sdk::{
    core::consensus::verifier::TrustRoot,
    modules::rofl::app::AppId
};

#[derive(Debug, Clone)]
pub enum NetworkMode {
    Mock,
    Localnet,
    Testnet,
    Mainnet,
}

pub fn network_mode() -> NetworkMode {
    if cfg!(feature = "observer-mock") {
        NetworkMode::Mock
    }
    else if cfg!(feature = "observer-localnet") {
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
    pub appid: AppId,
    pub mode: NetworkMode,
    pub trust_root: Option<TrustRoot>
}

impl ObserverConfig {
    pub fn from_mode(mode: NetworkMode) -> Self {
        match mode {
            NetworkMode::Mock => Self {
                mode,
                appid: "rofl1qqn9xndja7e2pnxhttktmecvwzz0yqwxsquqyxdf".into(),
                trust_root: None
            },
            NetworkMode::Localnet => Self {
                mode,
                appid: "rofl1qqn9xndja7e2pnxhttktmecvwzz0yqwxsquqyxdf".into(),
                trust_root: None
            },
            NetworkMode::Testnet => Self {
                mode,
                appid: "rofl1qqn9xndja7e2pnxhttktmecvwzz0yqwxsquqyxdf".into(),
                trust_root: None    // NOTE: update with `oasis rofl trust-root`
            },
            NetworkMode::Mainnet => Self {
                mode,
                appid: "rofl1qqn9xndja7e2pnxhttktmecvwzz0yqwxsquqyxdf".into(),
                trust_root: None    // NOTE: update with `oasis rofl trust-root`
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
