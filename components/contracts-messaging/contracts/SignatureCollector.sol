// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ECDSA } from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import { Signature } from './lib/SignedMessage.sol';
import { IAllowedSigner } from './IAllowedSigner.sol';
import { MessageOriginV1, MessageOriginV1Library, PackedOrigin } from './lib/MessageOriginV1.sol';
import { InvalidSignatureError, DuplicateSignatureError, SignerNotAllowedError } from './lib/Errors.sol';

contract SignatureCollector {

    using MessageOriginV1Library for MessageOriginV1;
    using MessageOriginV1Library for PackedOrigin;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct MessageState {
        Signature[] sigs;
        EnumerableSet.AddressSet signers;
    }

    struct State {
        mapping(bytes32 => MessageState) messages;
    }

    function _getState()
        private pure
        returns (State storage state)
    {
        // Randomly chosen, b32encode(urandom(20))[:29]
        bytes32 x = SlotDerivation.erc7201Slot("KUSFUGWY6HCJ5HGAHSUQLNTK7I2S3");

        assembly {
            state.slot := x
        }
    }

    function getMessageState(bytes32 messageId)
        private view
        returns (MessageState storage)
    {
        return _getState().messages[messageId];
    }

    function collect_signature(
        PackedOrigin memory packedOrigin,
        bytes32 messageHash,
        Signature calldata sig
    )
        external
    {
        address recovered;

        ECDSA.RecoverError err;

        bytes32 messageId = packedOrigin.hash(messageHash);

        ( recovered, err, ) = ECDSA.tryRecover(messageId, sig.r, sig.sv);

        require( err == ECDSA.RecoverError.NoError,
            InvalidSignatureError(messageId, uint8(err)) );

        MessageState storage ms = getMessageState(messageId);

        require( false == ms.signers.contains(recovered),
            DuplicateSignatureError(messageId, recovered));

        MessageOriginV1 memory origin = packedOrigin.unpack();

        // If a reciprocal contract exists for the sender, ask it if allowed
        // This allows for optional protocol-specific gating.
        // Note: This check provides best-effort DoS protection by limiting signature registration
        // but falls through on chains like zkSync where address derivation differs.
        // The core event observation model remains permissionless regardless.
        // See: https://docs.zksync.io/zksync-protocol/differences/evm-instructions#address-derivation
        if( origin.sender.code.length > 0 )
        {
            require( IAllowedSigner(origin.sender).isSignerAllowed(recovered),
                SignerNotAllowedError(messageId, recovered) );
        }

        ms.sigs.push(Signature(sig.r, sig.sv));

        ms.signers.add(recovered);
    }

    function signatures_count(bytes32 messageId)
        external view
        returns (uint)
    {
        return getMessageState(messageId).sigs.length;
    }

    function signatures_fetch(bytes32 messageId)
        external view
        returns (Signature[] memory)
    {
        return getMessageState(messageId).sigs;
    }

    function signers_fetch(bytes32 messageId)
        external view
        returns (address[] memory)
    {
        return getMessageState(messageId).signers.values();
    }
}
