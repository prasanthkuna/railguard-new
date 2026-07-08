import { describe, expect, it } from 'vitest';
import { buildPaymentIntent } from '../src/intent.js';

describe('intent', () => {
  it('builds canonical payment intent hash', () => {
    const { intentHash } = buildPaymentIntent({
      agentId: 'agent_support_bot_1',
      account: '0x0000000000000000000000000000000000000001',
      chainId: 84532,
      token: '0x00000000000000000000000000000000000000aa',
      recipient: '0x0000000000000000000000000000000000000b01',
      amountAtomic: 100_000_000n,
      resource: { method: 'POST', domain: 'api.vendor.com', path: '/v1/report' },
    });
    expect(intentHash).toMatch(/^0x[a-f0-9]{64}$/);
  });
});
