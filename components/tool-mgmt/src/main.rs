// SPDX-License-Identifier: Apache-2.0

use anyhow::Result;
use clap::{Parser, ValueEnum, Subcommand};
use alloy::{
    network::{Ethereum, EthereumWallet},
    primitives::Address,
    providers::{Provider, ProviderBuilder},
    transports::{http::reqwest::Url, Transport}
};

use observer_config::{NetworkMode, ObserverConfig};
use observer_common::{
    contracts::AtomicProxyFactory::{self, AtomicProxyFactoryInstance},
    privatekey::{k256ecdsa_from_default_mnemonic, K256ECDSAPrivateKeyArg},
    state::{State, DeployResult}
};

#[derive(Debug, Clone, Copy, ValueEnum)]
enum CliNetworkMode {
    Mock,
    Localnet,
    Testnet,
    Mainnet,
}

impl From<CliNetworkMode> for NetworkMode {
    fn from(wrapper: CliNetworkMode) -> NetworkMode {
        match wrapper {
            CliNetworkMode::Mock => NetworkMode::Mock,
            CliNetworkMode::Localnet => NetworkMode::Localnet,
            CliNetworkMode::Testnet => NetworkMode::Testnet,
            CliNetworkMode::Mainnet => NetworkMode::Mainnet,
        }
    }
}

#[derive(Debug, Parser)]
struct WriteArgs {
    /// Optionally set a title for what you are going to write about
    #[arg(short, long)]
    title: Option<String>,
}

#[derive(Subcommand, Debug)]
enum Commands {
    Write (WriteArgs)
}

/// Management tool for on-chain contracts
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short,long,value_enum,default_value_t=CliNetworkMode::Mock)]
    mode: CliNetworkMode,

    /// Private key or mnemonic for main account
    #[arg(long)]
    key: Option<K256ECDSAPrivateKeyArg>,

    /// Upstream RPC endpoint
    #[arg(long,default_value="http://localhost:8545")]
    rpc: Url,

    #[command(subcommand)]
    cmd: Commands
}

struct WriteCmd<'a,P,T> {
    state: &'a State<'a,P,T>,
    args: &'a WriteArgs
}

impl<'a,P,T> WriteCmd<'a,P,T>
where
    P: Provider<T, Ethereum>,
    T: Transport + Clone,
{
    fn new(state: &'a State<'a,P,T>, args: &'a WriteArgs) -> Self
    {
        Self { state, args }
    }

    async fn deploy_factory(&self) -> Result<DeployResult>
    {
        self.state
            .track_deployment(
                AtomicProxyFactory
                    ::deploy_builder(&self.state.upstream)
                    .into_transaction_request()
            ).await
    }

    async fn proxy_address(&self, factory_address: Address, creator: Address, name: String) -> Result<Address>
    {
        Ok(AtomicProxyFactoryInstance
            ::new(factory_address, &self.state.upstream)
            .getProxyAddress(creator, name)
            .call()
            .await?
            ._0)
    }

    async fn go(&self) -> Result<()>
    {
        let factory_address
            = self.deploy_factory()
                .await?
                .address;

        let proxy_address
            = self.proxy_address(
                factory_address,
                self.state.wallet.default_signer().address(),
                "example".to_string()).await?;

        println!("Contract Address: {:?}", proxy_address);

        Ok(())
    }
}

#[tokio::main]
async fn main () -> Result<()> {
    let all_args = Args::parse();
    let config = ObserverConfig::from_mode(all_args.mode.into());

    let wallet = EthereumWallet::from(match &all_args.key {
        Some(x) => x.into(),
        None => k256ecdsa_from_default_mnemonic()?
    });

    let provider = ProviderBuilder::new()
        .with_recommended_fillers()
        .wallet(wallet.clone())
        .on_http(all_args.rpc.clone());

    println!("Wallet Address: {}", wallet.default_signer().address());

    let state
        = State::new(&provider, &wallet, &config);

    match &all_args.cmd {
        Commands::Write(args) => WriteCmd::new(&state,args).go().await?
    }

    Ok(())
}
