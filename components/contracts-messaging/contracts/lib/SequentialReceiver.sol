// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ValidatorSet } from '../ValidatorSet.sol';
import { SignedMessage } from './SignedMessage.sol';
import { MessageOrigin, MessageOriginLibrary } from './MessageOrigin.sol';

library SequentialReceiver {

    struct State {
        mapping(bytes32 => bool) received;
    }

    function receiveOnce(
        State storage self,
        ValidatorSet validator,
        SignedMessage memory x
    )
        external
        returns (bytes32 messageId, MessageOrigin memory origin)
    {
        (messageId, origin) = validator.decode(x);

        self.received[messageId] = true;
    }
}
