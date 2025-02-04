// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';
import { Initializable } from '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import { ValidatorSet } from 'contracts-messaging/contracts/ValidatorSet.sol';
import { IEmitter, MessageOriginV1 } from 'contracts-messaging/contracts/IEmitter.sol';
import { SequentialReceiver } from 'contracts-messaging/contracts/lib/SequentialReceiver.sol';

import { IBridgeToken } from './IBridgeToken.sol';

struct BridgeTransferMessage {
    uint32 destChainId;
    uint256 amount;
    address recipient;
}

struct Settings {
    uint8 validAfterNBlocks;
    uint16 validAfterNSeconds;
    uint96 fee;
    uint96 minimumTransfer;

    IEmitter emitter;
    address feeCollector;
    ValidatorSet validator;
}

struct CommonState {
    Settings settings;
    mapping(uint32 => address) remoteEmitters;
    SequentialReceiver.State sequentialReceiverState;
    uint collectedFees;
}

abstract contract CommonEndpoint is Ownable, Initializable {

    using SequentialReceiver for SequentialReceiver.State;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor ()
        Ownable(address(0))
    {
        // Does nothing, as this is not meant to be used directly
        _disableInitializers();
    }

    function common_initialize(address in_owner, Settings memory in_settings)
        internal
    {
        _transferOwnership(in_owner);

        common_getState().settings = in_settings;
    }

    function owner_updateSettings(Settings memory in_settings)
        external
        onlyOwner
    {
        common_getState().settings = in_settings;
    }

    function owner_setRemoteEmitter(
        uint32 remoteChainId,
        address remoteEmitterAddress
    )
        external
        onlyOwner
    {
        common_getState().remoteEmitters[remoteChainId] = remoteEmitterAddress;
    }

    function common_getState()
        internal pure
        returns (CommonState storage commonState)
    {
        // Randomly chosen, b32encode(urandom(20))[:29]
        bytes32 x = SlotDerivation.erc7201Slot("CCCJVH6KDCMSHRVH7VZDVJFOIHJU3");

        assembly {
            commonState.slot := x
        }
    }

    error MinimumTransferError(uint minimum, uint amount);

    function common_sendTokensToRemoteChain(
        uint32 destChainId,
        address recipient,
        uint amount
    )
        internal
        returns (address feeCollector, uint fee)
    {
        CommonState storage state = common_getState();

        Settings storage settings = state.settings;

        require( amount > settings.minimumTransfer,
            MinimumTransferError(settings.minimumTransfer, amount));

        fee = settings.fee;

        feeCollector = settings.feeCollector;

        uint valueWithoutFee = amount - fee;

        state.collectedFees += fee;

        settings.emitter.send(
            abi.encode(
                BridgeTransferMessage({
                    destChainId: destChainId,
                    recipient: recipient,
                    amount: valueWithoutFee})),
            settings.validAfterNBlocks,
            settings.validAfterNSeconds);
    }

    error RemoteEmitterInvalid(address expected, address actual);

    error DestinationChainInvalid(uint32 expected, uint32 actual);

    function common_receiveTokensFromRemoteChain(bytes memory data)
        internal
        returns (address, uint)
    {
        CommonState storage state = common_getState();

        ValidatorSet validator = state.settings.validator;

        MessageOriginV1.Struct memory origin;

        bytes memory message;

        (,origin, message) = state.sequentialReceiverState.receiveOnce(validator, data);

        address expectedEmitter = state.remoteEmitters[origin.srcChainId];

        require( expectedEmitter == origin.emitterContract,
            RemoteEmitterInvalid(expectedEmitter, origin.emitterContract) );

        BridgeTransferMessage memory inner = abi.decode(message, (BridgeTransferMessage));

        require( inner.destChainId == block.chainid,
            DestinationChainInvalid(uint32(block.chainid), inner.destChainId) );

        return (inner.recipient, inner.amount);
    }
}
