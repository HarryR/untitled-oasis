// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { SignedMessage, decodeSignedMessage } from '../lib/SignedMessage.sol';

contract TestSignedMessage {
    function testDecodeSigned(SignedMessage memory m)
        external pure
        returns (bytes32 messageId, address[] memory addresses)
    {
        return decodeSignedMessage(m);
    }
}
