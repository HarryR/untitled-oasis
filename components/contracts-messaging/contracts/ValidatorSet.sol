// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import { IAllowedSigner } from './lib/IAllowedSigner.sol';
import { decodeSignedMessage, SignedMessage } from './lib/SignedMessage.sol';
import { MessageOrigin, MessageOriginLibrary } from './lib/MessageOrigin.sol';

contract ValidatorSet is Ownable, IAllowedSigner {

    using EnumerableSet for EnumerableSet.AddressSet;

    struct State {
        EnumerableSet.AddressSet signers;
        mapping(bytes32 => bool) received;
        uint threshold;
    }

    function _getState()
        private pure
        returns (State storage state)
    {
        // Randomly chosen, b32encode(urandom(20))[:29]
        bytes32 x = SlotDerivation.erc7201Slot("A55ZEMQDBKQ7IZEJZQMBN3Y6K55NR");

        assembly {
            state.slot := x
        }
    }

    constructor(
        address owner,
        address[] memory initial_signers,
        uint initial_threshold
    )
        Ownable(owner)
    {
        State storage state = _getState();

        for( uint i = 0; i < initial_signers.length; i++ )
        {
            state.signers.add(initial_signers[i]);
        }

        state.threshold = initial_threshold;
    }

    error ThresholdNotMetError(uint count, uint threshold);

    error DuplicateSignerError(address recovered);

    function internal_decode(SignedMessage memory x)
        internal view
        returns (
            MessageOrigin memory origin,
            bytes32 messageId,
            State storage state
        )
    {
        state = _getState();

        address[] memory signers;

        (messageId, signers) = decodeSignedMessage(x);

        require( signers.length >= state.threshold,
            ThresholdNotMetError(signers.length, state.threshold) );

        for( uint i = 0; i < signers.length; i++ )
        {
            require( state.signers.contains(signers[i]),
                DuplicateSignerError(signers[i]) );
        }

        origin = MessageOriginLibrary.unpack(x.packedOrigin);
    }

    function decode(SignedMessage memory x)
        external view
        returns (bytes32 messageId, MessageOrigin memory origin)
    {
        (origin, messageId,) = internal_decode(x);
    }

    function receiveOnce(SignedMessage memory x)
        external
        returns (bytes32 messageId, MessageOrigin memory origin)
    {
        State storage state;

        (origin, messageId, state) = internal_decode(x);

        state.received[messageId] = true;
    }

    function add(address value)
        external
        onlyOwner
    {
        State storage state = _getState();

        state.signers.add(value);
    }

    function remove(address value)
        external
        onlyOwner
    {
        State storage state = _getState();

        state.signers.remove(value);
    }

    function values()
        external view
        returns (address[] memory)
    {
        State storage state = _getState();

        return state.signers.values();
    }

    function isSignerAllowed(address value)
        external view
        returns (bool)
    {
        State storage state = _getState();

        return state.signers.contains(value);
    }

    function length()
        external view
        returns (uint)
    {
        State storage state = _getState();

        return state.signers.length();
    }
}
