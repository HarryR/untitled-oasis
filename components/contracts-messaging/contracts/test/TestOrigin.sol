// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { MessageOriginV1 } from '../lib/MessageOriginV1.sol';

contract TestOrigin {
    function testPack(MessageOriginV1.Struct memory origin)
        external pure
        returns (MessageOriginV1.Packed memory packedOrigin)
    {
        return MessageOriginV1.pack(origin);
    }

    function testUnpack(MessageOriginV1.Packed memory packedOrigin)
        external pure
        returns (MessageOriginV1.Struct memory origin)
    {
        return MessageOriginV1.unpack(packedOrigin);
    }
}
