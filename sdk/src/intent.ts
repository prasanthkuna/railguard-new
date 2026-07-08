import { type Address, type Hex, encodePacked, keccak256 } from 'viem';

export type PaymentIntentInput = {
  agentId: string;
  account: Address;
  chainId: number;
  token: Address;
  recipient: Address;
  amountAtomic: bigint;
  resource: { method: string; domain: string; path: string };
};

export function buildPaymentIntent(input: PaymentIntentInput) {
  const canonical = {
    agentId: input.agentId.toLowerCase(),
    account: input.account.toLowerCase(),
    chainId: input.chainId,
    token: input.token.toLowerCase(),
    recipient: input.recipient.toLowerCase(),
    amountAtomic: input.amountAtomic.toString(),
    domain: input.resource.domain.toLowerCase(),
    path: input.resource.path,
    method: input.resource.method.toUpperCase(),
  };
  const intentHash = keccak256(
    new TextEncoder().encode(JSON.stringify(canonical))
  );
  return { canonical, intentHash };
}

export const TRANSFER_SELECTOR = '0xa9059cbb' as Hex;

export function encodeSingleTransfer(token: Address, recipient: Address, amount: bigint): Hex {
  const callData = encodePacked(
    ['bytes4', 'address', 'uint256'],
    [TRANSFER_SELECTOR, recipient, amount]
  );
  return encodePacked(['address', 'uint256', 'bytes'], [token, 0n, callData]);
}
