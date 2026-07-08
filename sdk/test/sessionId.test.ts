import { describe, expect, it } from 'vitest';
import { deriveSessionId, sessionConfigPhysicalHash } from '../src/sessionId.js';

const cfg = {
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
} as const;

describe('sessionId', () => {
  it('derives deterministic session id', () => {
    const physical = sessionConfigPhysicalHash(cfg);
    expect(physical).toMatch(/^0x[a-f0-9]{64}$/);
    const id = deriveSessionId({
      chainId: 84532,
      adapter: '0x00000000000000000000000000000000000000c0',
      account: '0x0000000000000000000000000000000000000001',
      nonceKey: 12345n,
      config: cfg,
    });
    expect(id).toBe('0x52a14e7814be7dbf606ee36eb57bef03d9d9e50b72bd13097f14eb123d26b936');
  });
});
