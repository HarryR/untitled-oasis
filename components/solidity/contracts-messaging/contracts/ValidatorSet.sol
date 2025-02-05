// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import { decodeSignedMessage, SignedMessage } from './lib/SignedMessage.sol';
import { MessageDecoderV1Library } from './MessageDecoderV1.sol';
import { MessageOriginV1, MessageOriginV1Library, PackedOrigin } from './lib/MessageOriginV1.sol';
import { ThresholdNotMetError, SignerNotAllowedError } from './lib/Errors.sol';

/// @notice Manages a dynamic set of validators and validates multi-signature messages against a configurable threshold
contract ValidatorSet is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    using MessageOriginV1Library for PackedOrigin;

    event OnValidatorAdded(address who);

    event OnValidatorRemoved(address who);

    struct State {
        EnumerableSet.AddressSet allowedSigners;
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
            state.allowedSigners.add(initial_signers[i]);

            emit OnValidatorAdded(initial_signers[i]);
        }

        state.threshold = initial_threshold;

        internal_checkStateConsistency(state);
    }

    function internal_checkStateConsistency(State storage state)
        internal
        view
    {
        require( state.allowedSigners.length() > 0 );

        require( state.threshold <= state.allowedSigners.length() );

        require( state.threshold > 0 );
    }

    /// @notice Updates validator set configuration
    /// @dev Adds non-zero addresses and removes zero addresses from validator set. Only updates state for addresses not already in desired state.
    /// @param in_threshold New signature threshold requirement
    /// @param in_signers_delta Array of address changes: address(0) removes, non-zero adds
    /// @return added Number of new validators added
    /// @return removed Number of validators removed
    function onlyOwner_updateSettings(
        uint in_threshold,
        address[] memory in_signers_delta
    )
        external
        returns (uint added, uint removed)
    {
        State storage state = _getState();

        state.threshold = in_threshold;

        for( uint i = 0; i < in_signers_delta.length; i++ )
        {
            address s = in_signers_delta[i];

            if( s == address(0) )
            {
                if( state.allowedSigners.contains(s) )
                {
                    removed += 1;

                    state.allowedSigners.remove(s);

                    emit OnValidatorRemoved(s);
                }
            }
            else {
                if( ! state.allowedSigners.contains(s) )
                {
                    added += 1;

                    state.allowedSigners.add(s);

                    emit OnValidatorAdded(s);
                }
            }
        }

        internal_checkStateConsistency(state);
    }

    /// @notice Validates and decodes a signed message against current validator set
    /// @dev Requires minimum threshold of valid signatures from allowed signers
    /// @param data Raw message bytes to decode
    /// @return messageId Unique identifier of the message
    /// @return origin Decoded message origin data
    /// @custom:throws ThresholdNotMetError when signatures below threshold
    /// @custom:throws SignerNotAllowedError when signer not in validator set
    function decode(bytes calldata data)
        external view
        returns (
            bytes32 messageId,
            MessageOriginV1 memory origin,
            bytes memory message
    ) {
        State storage state = _getState();

        address[] memory signers;

        (messageId, origin, message, signers) = MessageDecoderV1Library.decodeSigned(data);

        require( signers.length >= state.threshold,
            ThresholdNotMetError(messageId, signers.length, state.threshold) );

        for( uint i = 0; i < signers.length; i++ )
        {
            require( state.allowedSigners.contains(signers[i]),
                SignerNotAllowedError(messageId, signers[i]) );
        }

        //origin = x.packedOrigin.unpack();
    }

    function threshold()
        external view
        returns (uint)
    {
        return _getState().threshold;
    }

    function values()
        external view
        returns (address[] memory)
    {
        return _getState().allowedSigners.values();
    }

    function contains(address value)
        external view
        returns (bool)
    {
        return _getState().allowedSigners.contains(value);
    }

    function containsAll(address[] calldata addressList)
        external view
        returns (bool)
    {
        EnumerableSet.AddressSet storage allowedSigners = _getState().allowedSigners;

        for( uint i = 0; i < addressList.length; i++ )
        {
            if( ! allowedSigners.contains(addressList[i]) )
            {
                return false;
            }
        }

        return true;
    }

    function length()
        external view
        returns (uint)
    {
        return _getState().allowedSigners.length();
    }
}
