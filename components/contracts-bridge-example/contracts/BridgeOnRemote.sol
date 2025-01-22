// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';
import { Initializable } from '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import { MessageEmitter } from 'contracts-messaging/contracts/MessageEmitter.sol';
import { ValidatorSet, MessageOrigin, SignedMessage } from 'contracts-messaging/contracts/ValidatorSet.sol';

import { BridgeTransferMessage } from './BridgeMessages.sol';
import { IBridgeToken } from './IBridgeToken.sol';

contract BridgeOnRemote is Ownable, Initializable {

    struct Settings {
        MessageEmitter emitter;
        IBridgeToken token;
        ValidatorSet validator;
    }

    struct State {
        Settings settings;
        mapping(uint32 => address) remoteEmitters;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor ()
        Ownable(address(0))
    {
        // Does nothing, as this is not meant to be used directly
        _disableInitializers();
    }

    function initialize(address in_owner, Settings memory in_settings)
        initializer
        external
    {
        _transferOwnership(in_owner);

        State storage state = _getState();

        state.settings = in_settings;
    }

    function owner_updateSettings(Settings memory in_settings)
        external
        onlyOwner
    {
        State storage state = _getState();

        state.settings = in_settings;
    }

    function owner_setRemoteEmitter(
        uint32 remoteChainId,
        address remoteEmitterAddress
    )
        external
        onlyOwner
    {
        State storage state = _getState();

        state.remoteEmitters[remoteChainId] = remoteEmitterAddress;
    }

    function _getState()
        private pure
        returns (State storage state)
    {
        // Randomly chosen, b32encode(urandom(20))[:29]
        bytes32 x = SlotDerivation.erc7201Slot("CCCJVH6KDCMSHRVH7VZDVJFOIHJU3");

        assembly {
            state.slot := x
        }
    }

    function sendTokensToRemoteChain(uint32 destChainId, address recipient, uint amount)
        public
        returns (bytes32 messageId)
    {
        Settings storage settings = _getState().settings;

        settings.token.bridge_burn(msg.sender, amount);

        messageId = settings.emitter.send(
            abi.encode(
                BridgeTransferMessage({
                    destChainId: destChainId,
                    recipient: recipient,
                    amount: amount
                })
            ));
    }

    error RemoteEmitterInvalid(address expected, address actual);

    error DestinationChainInvalid(uint32 expected, uint32 actual);

    function receiveTokensFromRemoteChain(SignedMessage memory x)
        public
    {
        State storage state = _getState();

        Settings storage settings = state.settings;

        (,MessageOrigin memory origin) = settings.validator.receiveOnce(x);

        address expectedEmitter = state.remoteEmitters[origin.srcChainId];

        require( expectedEmitter == x.emitterContract,
            RemoteEmitterInvalid(expectedEmitter, x.emitterContract) );

        BridgeTransferMessage memory inner = abi.decode(x.message, (BridgeTransferMessage));

        require( inner.destChainId == block.chainid,
            DestinationChainInvalid(uint32(block.chainid), inner.destChainId) );

        settings.token.bridge_mint(inner.recipient, inner.amount);
    }
}
