// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ValidatorSet } from '../ValidatorSet.sol';
import { SignedMessage } from './SignedMessage.sol';
import { MessageOriginV1 } from './MessageOriginV1.sol';
import { DuplicateMessageError } from './Errors.sol';

library SequentialReceiver {

    struct State {
        mapping(bytes32 => bool) received;
    }

    function receiveOnce(
        State storage self,
        ValidatorSet validator,
        bytes memory data
    )
        internal
        returns (
            bytes32 messageId,
            MessageOriginV1 memory origin,
            bytes memory message
    ) {
        require( self.received[messageId] == false,
            DuplicateMessageError(messageId) );

        (messageId, origin, message) = validator.decode(data);

        self.received[messageId] = true;
    }
}
