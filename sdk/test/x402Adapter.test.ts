import { describe, expect, it } from 'vitest';
import { createX402Guard, parseResourceUrl } from '../src/x402Adapter.js';

describe('x402Adapter', () => {
  it('createX402Guard evaluates allow within dev policy', async () => {
    const guard = createX402Guard('agent_test');
    const decision = await guard.evaluate({
      agentId: 'agent_test',
      payer: '0x1111111111111111111111111111111111111111',
      payTo: '0x2222222222222222222222222222222222222222',
      amountAtomic: 50_000n,
      asset: 'USDC',
      network: 'eip155:84532',
      resource: parseResourceUrl('https://api.example.com/v1/data'),
    });
    expect(decision.blocked).toBe(false);
    expect(guard.lastReceipt?.decision).toBe('allow');
  });

  it('createX402Guard blocks over per-call cap', async () => {
    const guard = createX402Guard('agent_test');
    const decision = await guard.evaluate({
      agentId: 'agent_test',
      payer: '0x1111111111111111111111111111111111111111',
      payTo: '0x2222222222222222222222222222222222222222',
      amountAtomic: 9_000_000n,
      asset: 'USDC',
      network: 'eip155:84532',
      resource: parseResourceUrl('https://api.example.com/v1/data'),
    });
    expect(decision.blocked).toBe(true);
  });
});
