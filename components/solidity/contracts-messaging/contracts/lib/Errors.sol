// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

error ThresholdNotMetError(bytes32 messageId, uint count, uint threshold);

error InvalidSignatureError(bytes32 messageId, uint8 ecdsaRecoverError);

error DuplicateSignatureError(bytes32 messageId, address signer);

error SignerNotAllowedError(bytes32 messageId, address signer);

error DuplicateMessageError(bytes32 messageId);

error NoSignaturesError(bytes32 messageId);

error UnexpectedVersionError(uint8 actual, uint8 expected);
