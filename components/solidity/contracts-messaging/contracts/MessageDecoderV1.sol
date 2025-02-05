// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { SignedMessage, decodeSignedMessage } from './lib/SignedMessage.sol';
import { UnexpectedVersionError } from './lib/Errors.sol';
import { MessageOriginV1, MessageOriginV1Library, PackedOrigin } from './lib/MessageOriginV1.sol';

library MessageDecoderV1Library {

    using MessageOriginV1Library for PackedOrigin;

    uint8 public constant VERSION = uint8(1);

    function decodeSigned(bytes calldata data)
        internal pure
        returns (
            bytes32 messageId,
            MessageOriginV1 memory origin,
            bytes memory message,
            address[] memory signers
    ) {
        SignedMessage memory sm = abi.decode(data, (SignedMessage));

        message = sm.message;

        (messageId, signers) = decodeSignedMessage(sm);

        origin = sm.packedOrigin.unpack();

        require( origin.messageVersion == VERSION,
            UnexpectedVersionError(origin.messageVersion, VERSION));
    }

    function decodeUnsigned(bytes calldata data)
        internal pure
        returns (
            bytes32 messageId,
            MessageOriginV1 memory origin,
            bytes memory message
    ) {
        require( data.length > 64 );

        require( data[0] == bytes1(VERSION),
            UnexpectedVersionError(uint8(data[1]), VERSION));

        PackedOrigin memory packed = abi.decode(data[:64], (PackedOrigin));

        messageId = packed.hash(data[64:]);

        origin = packed.unpack();

        message = data[64:];
    }
}

contract MessageDecoderV1 {

    function decodeSigned(bytes calldata data)
        external pure
        returns (
            bytes32 messageId,
            MessageOriginV1 memory origin,
            bytes memory message,
            address[] memory signers
    ) {
        return MessageDecoderV1Library.decodeSigned(data);
    }

    function decodeUnsigned(bytes calldata data)
        external pure
        returns (
            bytes32 messageId,
            MessageOriginV1 memory origin,
            bytes memory message
    ) {
        return MessageDecoderV1Library.decodeUnsigned(data);
    }
}
