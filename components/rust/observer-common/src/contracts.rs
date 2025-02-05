// SPDX-License-Identifier: Apache-2.0

use alloy::sol;

sol!(
    #[sol(rpc)]
    BridgeOnRemote,
    "../../solidity/artifacts/unstable/BridgeOnRemote.json"
);

sol!(
    #[sol(rpc)]
    BridgeOnSapphire,
    "../../solidity/artifacts/unstable/BridgeOnSapphire.json"
);

sol!(
    #[sol(rpc)]
    BridgeToken,
    "../../solidity/artifacts/unstable/BridgeToken.json"
);

sol!(
    #[sol(rpc)]
    AtomicProxyFactory,
    "../../solidity/artifacts/unstable/AtomicProxyFactory.json"
);

sol!(
    #[sol(rpc)]
    IAllowedSigner,
    "../../solidity/artifacts/unstable/IAllowedSigner.json"
);

sol!(
    #[sol(rpc)]
    SignatureCollector,
    "../../solidity/artifacts/unstable/SignatureCollector.json"
);

sol!(
    #[sol(rpc)]
    IEmitter,
    "../../solidity/artifacts/unstable/IEmitter.json"
);

sol!(
    #[sol(rpc)]
    MessageDecoderV1,
    "../../solidity/artifacts/unstable/MessageDecoderV1.json"
);

sol!(
    #[sol(rpc)]
    MessageEmitterV1,
    "../../solidity/artifacts/unstable/MessageEmitterV1.json"
);

sol!(
    #[sol(rpc)]
    ValidatorSet,
    "../../solidity/artifacts/unstable/ValidatorSet.json"
);
