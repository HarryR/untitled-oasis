// SPDX-License-Identifier: Apache-2.0

use serde_json::{json, Value};
use anyhow::{Result, anyhow};

/// Converts a byte array into its hexadecimal string representation
pub fn encode_hex(bytes: &[u8]) -> String {
    let mut hex = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        hex.push_str(&format!("{:02x}", byte));
    }
    hex
}

/// Parses a hexadecimal string (with or without '0x' prefix) into a byte array
/// Returns an error if the input string is malformed
pub fn decode_hex(hex: &str) -> Result<Vec<u8>> {
    let hex = hex.trim_start_matches("0x");
    let mut bytes = Vec::with_capacity(hex.len() / 2);
    for i in (0..hex.len()).step_by(2) {
        if i + 2 > hex.len() {
            return Err(anyhow::anyhow!("Invalid hex string length"));
        }
        let byte = u8::from_str_radix(&hex[i..i + 2], 16)
            .map_err(|e| anyhow::anyhow!("Invalid hex string: {}", e))?;
        bytes.push(byte);
    }
    Ok(bytes)
}

/// Retrieves the current block number from the specified blockchain
/// Returns the block number in hexadecimal format
pub async fn get_latest_block(rpc_url: &str) -> Result<String> {
    let payload = json!({
        "jsonrpc": "2.0",
        "method": "eth_blockNumber",
        "params": [],
        "id": 1
    });

    let host = rpc_url
        .trim_start_matches("https://")
        .trim_start_matches("http://")
        .split('/')
        .next()
        .ok_or_else(|| anyhow!("Invalid RPC URL format"))?;

    let agent = rofl_utils::https::agent();
    let mut response = agent
        .post(rpc_url)
        .header("Content-Type", "application/json")
        .header("Host", host)
        .send_json(&payload)?;

    let body = response.body_mut().read_json::<Value>()?;

    body["result"]
        .as_str()
        .map(String::from)
        .ok_or_else(|| anyhow::anyhow!("Invalid block number response"))
}