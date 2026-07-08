import { type Address, type Hex, recoverAddress, sha256, toBytes } from 'viem';
import { type SessionConfigInput } from './sessionId.js';

export type SessionAuthorizationInput = SessionConfigInput & {
  account: Address;
  nonceKey: bigint;
  policyHash: Hex;
  chainId: number;
  adapter: Address;
};

export type ReceiptPayload = {
  receiptVersion: string;
  decisionId: string;
  decision: string;
  reasonCodes: string[];
  agentId: string;
  intentHash: Hex;
  policyHash: Hex;
  chainId: number;
  token: Address;
  recipient: Address;
  amountAtomic: string;
  signerKeyID: string;
  createdAt: string;
  sessionId?: string;
  nonceKey?: string;
  allowBatch?: boolean;
  validUntil?: number;
};

export function buildSessionAuthorization(input: SessionAuthorizationInput) {
  return {
    domain: {
      name: 'Railguard',
      version: '1',
      chainId: input.chainId,
      verifyingContract: input.adapter,
    },
    types: {
      SessionAuthorization: [
        { name: 'account', type: 'address' },
        { name: 'nonceKey', type: 'uint192' },
        { name: 'sessionKey', type: 'address' },
        { name: 'token', type: 'address' },
        { name: 'allowedTarget', type: 'address' },
        { name: 'allowedRecipient', type: 'address' },
        { name: 'allowedSelector', type: 'bytes4' },
        { name: 'maxPerTransfer', type: 'uint256' },
        { name: 'maxTotalSpend', type: 'uint256' },
        { name: 'validAfter', type: 'uint48' },
        { name: 'validUntil', type: 'uint48' },
        { name: 'allowBatch', type: 'bool' },
        { name: 'policyHash', type: 'bytes32' },
      ],
    },
    primaryType: 'SessionAuthorization' as const,
    message: {
      account: input.account,
      nonceKey: input.nonceKey,
      sessionKey: input.sessionKey,
      token: input.token,
      allowedTarget: input.allowedTarget,
      allowedRecipient: input.allowedRecipient,
      allowedSelector: input.allowedSelector,
      maxPerTransfer: input.maxPerTransfer,
      maxTotalSpend: input.maxTotalSpend,
      validAfter: Number(input.validAfter),
      validUntil: Number(input.validUntil),
      allowBatch: input.allowBatch,
      policyHash: input.policyHash,
    },
  };
}

/** Mirrors Go receipt.Payload json.Marshal field order for SignGate hash parity. */
export function hashReceiptPayload(payload: ReceiptPayload): Hex {
  const canonical: Record<string, unknown> = {
    receiptVersion: payload.receiptVersion,
    decisionId: payload.decisionId,
    decision: payload.decision,
    reasonCodes: payload.reasonCodes,
    agentId: payload.agentId,
    intentHash: payload.intentHash,
    policyHash: payload.policyHash,
  };
  if (payload.sessionId) canonical.sessionId = payload.sessionId;
  if (payload.nonceKey) canonical.nonceKey = payload.nonceKey;
  canonical.chainId = payload.chainId;
  canonical.token = payload.token;
  canonical.recipient = payload.recipient;
  canonical.amountAtomic = payload.amountAtomic;
  canonical.allowBatch = payload.allowBatch ?? false;
  if (payload.validUntil) canonical.validUntil = payload.validUntil;
  canonical.signerKeyID = payload.signerKeyID;
  canonical.createdAt = payload.createdAt;
  return sha256(toBytes(JSON.stringify(canonical)));
}

export function verifyReceiptHash(input: {
  payload: ReceiptPayload;
  receiptHash: Hex;
}): boolean {
  return hashReceiptPayload(input.payload).toLowerCase() === input.receiptHash.toLowerCase();
}

export async function verifyReceiptSignature(input: {
  payload: ReceiptPayload;
  receiptHash: Hex;
  signature: Hex;
  expectedSigner: Address;
}): Promise<boolean> {
  if (!verifyReceiptHash({ payload: input.payload, receiptHash: input.receiptHash })) {
    return false;
  }
  const recovered = await recoverAddress({ hash: input.receiptHash, signature: input.signature });
  return recovered.toLowerCase() === input.expectedSigner.toLowerCase();
}

/** @deprecated Use verifyReceiptHash or verifyReceiptSignature. */
export const verifyReceipt = verifyReceiptHash;
