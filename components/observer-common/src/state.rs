// SPDX-License-Identifier: Apache-2.0

use std::marker::PhantomData;
use anyhow::Result;
use alloy::{
    network::{Ethereum, EthereumWallet, Network, ReceiptResponse},
    primitives::{Address, TxHash}, providers::Provider,
    transports::Transport
};

use observer_config::ObserverConfig;

pub struct DeployResult {
    pub tx_hash: TxHash,
    pub address: Address
}

pub struct State<'a,P,T>
{
    pub upstream: &'a P,
    pub wallet: &'a EthereumWallet,
    pub config: &'a ObserverConfig,
    _get_rid_of_me: PhantomData<T>,
}

impl<'a,P,T> State<'a,P,T>
where
    P: Provider<T, Ethereum>,
    T: Transport + Clone
{
    pub fn new(
        upstream: &'a P,
        wallet: &'a EthereumWallet,
        config: &'a ObserverConfig
    ) -> Self {
        Self {
            upstream,
            wallet,
            config,
             _get_rid_of_me: PhantomData
        }
    }

    pub async fn track_deployment(
        &self,
        tx: <Ethereum as Network>::TransactionRequest
    ) -> Result<DeployResult>
    {
        let ptx
            = self.upstream
                .send_transaction(tx)
                .await?;

        let tx_hash = ptx.tx_hash().clone();

        let receipt
            = ptx
                .get_receipt()
                .await?;

        match (receipt.status(), receipt.contract_address()) {
            (true, Some(address)) => Ok(DeployResult{tx_hash, address}),
            _ => Err(anyhow::anyhow!("Deployment failed"))
        }
    }
}
