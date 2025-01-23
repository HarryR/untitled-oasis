// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ECDSA } from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';

import { Signature } from './lib/SignedMessage.sol';
import { IAllowedSigner } from './IAllowedSigner.sol';
import { PackedOrigin, MessageOrigin, MessageOriginLibrary } from './lib/MessageOrigin.sol';

contract SignatureCollector {

    using MessageOriginLibrary for PackedOrigin;

    struct State {
        mapping(bytes32 => Signature[]) sigs;
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

        require( err == ECDSA.RecoverError.NoError );

        MessageOrigin memory origin = packedOrigin.unpack();

        // If a reciprocal contract exists for the sender, ask it if allowed
        // This allows for optional protocol-specific gating.
        // Note: This check provides best-effort DoS protection by limiting signature registration
        // but falls through on chains like zkSync where address derivation differs.
        // The core event observation model remains permissionless regardless.
        // See: https://docs.zksync.io/zksync-protocol/differences/evm-instructions#address-derivation
        if( origin.sender.code.length > 0 )
        {
            require( IAllowedSigner(origin.sender).isSignerAllowed(recovered) );
        }

        State storage state = _getState();

        state.sigs[messageId].push(Signature(sig.r, sig.sv));
    }

    function signers_count(bytes32 messageId)
        external view
        returns (uint)
    {
        State storage state = _getState();

        return state.sigs[messageId].length;
    }

    function signers_fetch(bytes32 messageId)
        external view
        returns (Signature[] memory)
    {
        State storage state = _getState();

        return state.sigs[messageId];
    }
}
