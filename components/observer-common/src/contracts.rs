// SPDX-License-Identifier: Apache-2.0

use alloy::sol;

sol!(
    #[sol(rpc)]
    BridgeOnRemote,
    "../../artifacts/unstable/BridgeOnRemote.json"
);

sol!(
    #[sol(rpc)]
    BridgeOnSapphire,
    "../../artifacts/unstable/BridgeOnSapphire.json"
);

sol!(
    #[sol(rpc)]
    BridgeToken,
    "../../artifacts/unstable/BridgeToken.json"
);

sol!(
    #[sol(rpc)]
    AtomicProxyFactory,
    "../../artifacts/unstable/AtomicProxyFactory.json"
);

sol!(
    #[sol(rpc)]
    IAllowedSigner,
    "../../artifacts/unstable/IAllowedSigner.json"
);

sol!(
    #[sol(rpc)]
    SignatureCollector,
    "../../artifacts/unstable/SignatureCollector.json"
);

sol!(
    #[sol(rpc)]
    IEmitter,
    "../../artifacts/unstable/IEmitter.json"
);

sol!(
    #[sol(rpc)]
    MessageDecoderV1,
    "../../artifacts/unstable/MessageDecoderV1.json"
);

sol!(
    #[sol(rpc)]
    MessageEmitterV1,
    "../../artifacts/unstable/MessageEmitterV1.json"
);

sol!(
    #[sol(rpc)]
    ValidatorSet,
    "../../artifacts/unstable/ValidatorSet.json"
);
