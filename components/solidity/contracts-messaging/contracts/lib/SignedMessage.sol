// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ECDSA } from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import { MessageOriginV1, PackedOrigin, MessageOriginV1Library } from './MessageOriginV1.sol';
import { DuplicateSignatureError, NoSignaturesError, InvalidSignatureError } from './Errors.sol';

struct Signature {
    bytes32 r;
    bytes32 sv;
}

struct SignedMessage {
    Signature[] sigs;
    PackedOrigin packedOrigin;
    bytes message;
}

using MessageOriginV1Library for PackedOrigin;

function decodeSignedMessage(SignedMessage memory x)
    pure
    returns (bytes32 messageId, address[] memory addresses)
{
    uint nSigs = x.sigs.length;

    messageId = x.packedOrigin.hash(x.message);

    addresses = new address[](nSigs);

    require( addresses.length > 0,
        NoSignaturesError(messageId) );

    // Recover addresses for all signers
    for( uint i = 0; i < nSigs; i++ )
    {
        ECDSA.RecoverError err;

        Signature memory sig = x.sigs[i];

        ( addresses[i], err, ) = ECDSA.tryRecover(messageId, sig.r, sig.sv);

        require( err == ECDSA.RecoverError.NoError,
             InvalidSignatureError(messageId, uint8(err)));
    }

    // Ensure there are no duplicate signers
    for( uint i = 0; i < nSigs; i++ )
    {
        for( uint j = 0; j < nSigs; j++ )
        {
            if( i == j )
            {
                continue;
            }

            require( addresses[i] != addresses[j],
                DuplicateSignatureError(messageId, addresses[i]) );
        }
    }
}
