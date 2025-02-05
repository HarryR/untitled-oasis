// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { MessageOriginV1, PackedOrigin, MessageOriginV1Library } from '../lib/MessageOriginV1.sol';

contract TestOrigin {
    function testPack(MessageOriginV1 memory origin)
        external pure
        returns (PackedOrigin memory packedOrigin)
    {
        return MessageOriginV1Library.pack(origin);
    }

    function testUnpack(PackedOrigin memory packedOrigin)
        external pure
        returns (MessageOriginV1 memory origin)
    {
        return MessageOriginV1Library.unpack(packedOrigin);
    }
}
