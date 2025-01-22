// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Address } from '@openzeppelin/contracts/utils/Address.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';

import { MessageEmitter } from 'contracts-messaging/contracts/MessageEmitter.sol';
import { ValidatorSet, MessageOrigin, SignedMessage } from 'contracts-messaging/contracts/ValidatorSet.sol';

import { BridgeTransferMessage } from './BridgeMessages.sol';

contract BridgeOnSapphire is Ownable {

    struct Settings {
        MessageEmitter emitter;
        uint fee;
        uint minimumTransfer;
        address feeCollector;
        ValidatorSet validator;
    }

    struct State {
        Settings settings;
        mapping(uint32 => address) remoteEmitters;
        uint collectedFees;
    }

    function _getState()
        private pure
        returns (State storage state)
    {
        // Randomly chosen, b32encode(urandom(20))[:29]
        bytes32 x = SlotDerivation.erc7201Slot("YPTXKJWHZ4YG7ZBPLBWMR4W7MOPPU");

        assembly {
            state.slot := x
        }
    }

    constructor (Settings memory in_settings)
        Ownable(msg.sender)
    {
        require( in_settings.minimumTransfer > in_settings.fee );

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

    function owner_withdrawFees()
        external
        onlyOwner
    {
        State storage state = _getState();

        uint collectedFees = state.collectedFees;

        require( collectedFees > 0 );

        state.collectedFees = 0;

        Address.sendValue(payable(msg.sender), collectedFees);
    }

    error MinimumTransferError(uint expected, uint actual);

    function sendTokensToRemoteChain(uint32 destChainId, address recipient)
        public
        payable
    {
        State storage state = _getState();

        Settings memory settings = state.settings;

        require( msg.value > settings.minimumTransfer,
            MinimumTransferError(settings.minimumTransfer, msg.value));

        uint valueWithoutFee = msg.value - settings.fee;

        state.collectedFees += settings.fee;

        MessageEmitter emitter = state.settings.emitter;

        emitter.send(
            abi.encode(
                BridgeTransferMessage({
                    destChainId: destChainId,
                    recipient: recipient,
                    amount: valueWithoutFee
                })));

        // emit MessageId
    }

    error RemoteEmitterInvalid(address expected, address actual);

    error DestinationChainInvalid(uint32 expected, uint32 actual);

    function receiveTokensFromRemoteChain(SignedMessage memory x)
        public
    {
        State storage state = _getState();

        ValidatorSet validator = state.settings.validator;

        (,MessageOrigin memory origin) = validator.receiveOnce(x);

        address expectedEmitter = state.remoteEmitters[origin.srcChainId];

        require( expectedEmitter == x.emitterContract,
            RemoteEmitterInvalid(expectedEmitter, x.emitterContract) );

        BridgeTransferMessage memory inner = abi.decode(x.message, (BridgeTransferMessage));

        require( inner.destChainId == block.chainid,
            DestinationChainInvalid(uint32(block.chainid), inner.destChainId) );

        Address.sendValue(payable(inner.recipient), inner.amount);
    }
}
