import { describe, expect, it } from 'vitest';
import { hashTypedData } from 'viem';
import { buildSessionAuthorization } from '../src/eip712.js';

const eip712VectorAdapter = '0x2e234DAe75C793f67A35089C9d99245E1C58470b';
const eip712VectorDigest =
  '0xe500012fc5fb6423b2c95575f276c554190b953c054f9183465e2783d5bfa7a1';

describe('eip712', () => {
  it('builds session authorization typed data', () => {
    const td = buildSessionAuthorization({
      account: '0x0000000000000000000000000000000000000001',
      nonceKey: 12345n,
      sessionKey: '0x0000000000000000000000000000000000000002',
      token: '0x00000000000000000000000000000000000000aa',
      allowedTarget: '0x00000000000000000000000000000000000000aa',
      allowedRecipient: '0x0000000000000000000000000000000000000b01',
      allowedSelector: '0xa9059cbb',
      maxPerTransfer: 100_000_000n,
      maxTotalSpend: 500_000_000n,
      validAfter: 1n,
      validUntil: 9_999_999_999n,
      allowBatch: false,
      policyHash: '0x0000000000000000000000000000000000000000000000000000000000000011',
      chainId: 84532,
      adapter: eip712VectorAdapter,
    });
    expect(td.primaryType).toBe('SessionAuthorization');
    expect(td.domain.name).toBe('Railguard');
    expect(hashTypedData(td)).toBe(eip712VectorDigest);
  });
});
