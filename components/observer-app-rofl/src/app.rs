// SPDX-License-Identifier: Apache-2.0

use oasis_runtime_sdk::modules::rofl::app::prelude::*;
use observer_config::ObserverConfig;

pub struct ObserverApp {
    config: ObserverConfig
}

impl ObserverApp {
    pub fn new () -> Self {
        Self {
            config: ObserverConfig::new()
        }
    }
}

#[async_trait]
impl App for ObserverApp
{
    const VERSION: Version = sdk::version_from_cargo!();

    fn id() -> AppId {
        ObserverConfig::new().appid
    }

    fn consensus_trust_root() -> Option<TrustRoot> {
        ObserverConfig::new().trust_root
    }

    async fn run(self: Arc<Self>, _env: Environment<Self>) {
        println!("App Started!");
    }

    async fn on_runtime_block(
        self: Arc<Self>,
        _env: Environment<Self>,
        _round: u64
    ) {
        println!("Block Received!");
    }
}

pub fn observer_main () {
    ObserverApp::new().start();
}
