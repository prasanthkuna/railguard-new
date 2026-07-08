import { type Address, type Hex, encodeAbiParameters, keccak256, parseAbiParameters } from 'viem';

export type SessionConfigInput = {
  sessionKey: Address;
  token: Address;
  allowedTarget: Address;
  allowedRecipient: Address;
  allowedSelector: Hex;
  maxPerTransfer: bigint;
  maxTotalSpend: bigint;
  validAfter: bigint;
  validUntil: bigint;
  allowBatch: boolean;
};

export function sessionConfigPhysicalHash(config: SessionConfigInput): Hex {
  return keccak256(
    encodeAbiParameters(
      parseAbiParameters(
        'address, address, address, address, bytes4, uint256, uint256, uint48, uint48, bool'
      ),
      [
        config.sessionKey,
        config.token,
        config.allowedTarget,
        config.allowedRecipient,
        config.allowedSelector,
        config.maxPerTransfer,
        config.maxTotalSpend,
        Number(config.validAfter),
        Number(config.validUntil),
        config.allowBatch,
      ]
    )
  );
}

export function deriveSessionId(params: {
  chainId: number;
  adapter: Address;
  account: Address;
  nonceKey: bigint;
  config: SessionConfigInput;
}): Hex {
  const physical = sessionConfigPhysicalHash(params.config);
  return keccak256(
    encodeAbiParameters(parseAbiParameters('uint256, address, address, uint192, bytes32'), [
      BigInt(params.chainId),
      params.adapter,
      params.account,
      params.nonceKey,
      physical,
    ])
  );
}
