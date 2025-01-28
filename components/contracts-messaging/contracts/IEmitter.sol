// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { MessageOriginV1 } from './lib/MessageOriginV1.sol';

interface IEmitter {
    function send(
        bytes memory message,
        uint8 validAfterNBlocks,
        uint16 validAfterNSeconds
    ) external returns (bytes32);

    function decodeSigned(bytes calldata data)
        external view
        returns (
            bytes32 messageId,
            MessageOriginV1.Struct memory origin,
            bytes memory message,
            address[] memory signers
        );
}
