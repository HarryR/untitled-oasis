// SPDX-License-Identifier: Apache-2.0

use std::str::FromStr;
use thiserror::Error;
use anyhow::Result;
use alloy::{
    hex::FromHex,
    primitives::{FixedBytes, B256},
    signers::{
        k256::ecdsa::SigningKey,
        local::{
            coins_bip39::English,
            LocalSigner,
            LocalSignerError,
            MnemonicBuilder,
            PrivateKeySigner
        }
    }
};


#[derive(Debug, PartialEq)]
struct MnemonicInfo {
    phrase: String,
    index: u32,
}

fn parse_mnemonic(phrase: &str) -> MnemonicInfo {
    let words: Vec<&str> = phrase.split_whitespace().collect();

    // Check if last word is a positive integer
    if let Some(last_word) = words.last() {
        if let Ok(num) = last_word.parse::<u32>() {
            return MnemonicInfo {
                phrase: words[..words.len()-1].join(" "),
                index: num,
            };
        }
    }

    // If no number found, return original phrase with index 0
    MnemonicInfo {
        phrase: phrase.to_string(),
        index: 0,
    }
}


#[derive(Error, Debug)]
pub enum MnemonicError
{
    #[error("failed to get index")]
    IndexError(#[source]LocalSignerError),

    #[error("failed to build signer from mnemonic")]
    BuildError(#[source]LocalSignerError)
}

impl From<MnemonicError> for String
{
    fn from(err: MnemonicError) -> Self {
        err.to_string()
    }
}


pub fn k256ecdsa_from_mnemonic(phrase: &str) -> Result<LocalSigner<SigningKey>, MnemonicError>
{
    let info = parse_mnemonic(phrase);

    MnemonicBuilder::<English>::default()
        .phrase(info.phrase)
        .index(info.index)
        .map_err(MnemonicError::IndexError)?
        .build()
        .map_err(MnemonicError::BuildError)
}

const DEFAULT_MNEMONIC:&str = "test test test test test test test test test test test junk";

pub fn k256ecdsa_from_default_mnemonic() -> Result<LocalSigner<SigningKey>, MnemonicError>
{
    k256ecdsa_from_mnemonic(DEFAULT_MNEMONIC)
}


#[derive(Debug,Clone)]
pub struct K256ECDSAPrivateKeyArg(PrivateKeySigner);

impl<'a> From<&'a K256ECDSAPrivateKeyArg> for LocalSigner<SigningKey>
{
    fn from(arg: &'a K256ECDSAPrivateKeyArg) -> Self
    {
        arg.0.clone()
    }
}

fn k256ecdsa_key_from_bytes(bytes: FixedBytes<32>) -> Result<PrivateKeySigner,String>
{
    PrivateKeySigner::from_bytes(&bytes)
        .map_err(|e| format!("parsing private key: {e}"))
}


/// Parse PrivateKeySigner from hex secret, or mnemonic with optional index
impl FromStr for K256ECDSAPrivateKeyArg
{
    type Err = String;

    fn from_str(s:&str) -> Result<Self,Self::Err>
    {
        match s.contains(' ')
        {
            // parse from hex string
            false =>
                B256::from_hex(s)
                    .map_err(|e|format!("Invalid private key hex: {e}"))
                    .and_then(k256ecdsa_key_from_bytes)
                    .map(K256ECDSAPrivateKeyArg),

            // parse mnemonic, with optional index at the end
            true =>
                Ok(K256ECDSAPrivateKeyArg(k256ecdsa_from_mnemonic(s)?))
        }
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_phrase_index() {
        // Test with numeric index
        assert_eq!(parse_mnemonic("abandon ability able 123").index, 123);
        assert_eq!(parse_mnemonic("single 0").index, 0);
        assert_eq!(parse_mnemonic("test phrase 999999").index, 999999);

        // Test without numeric index
        assert_eq!(parse_mnemonic("abandon ability able").index, 0);
        assert_eq!(parse_mnemonic("").index, 0);
        assert_eq!(parse_mnemonic("test abc").index, 0);

        // Test with non-integer last word
        assert_eq!(parse_mnemonic("test 12.34").index, 0);
        assert_eq!(parse_mnemonic("test -123").index, 0);
        assert_eq!(parse_mnemonic("test 123abc").index, 0);
    }

    #[test]
    fn test_phrase_without_index() {
        // Test with numeric index
        assert_eq!(
            parse_mnemonic("abandon ability able 123").phrase,
            "abandon ability able"
        );
        assert_eq!(parse_mnemonic("single 0").phrase, "single");
        assert_eq!(
            parse_mnemonic("test phrase 999999").phrase,
            "test phrase"
        );

        // Test without numeric index
        assert_eq!(
            parse_mnemonic("abandon ability able").phrase,
            "abandon ability able"
        );
        assert_eq!(parse_mnemonic("").phrase, "");
        assert_eq!(parse_mnemonic("test abc").phrase, "test abc");

        // Test with non-integer last word
        assert_eq!(parse_mnemonic("test 12.34").phrase, "test 12.34");
        assert_eq!(parse_mnemonic("test -123").phrase, "test -123");
        assert_eq!(parse_mnemonic("test 123abc").phrase, "test 123abc");
    }
}
