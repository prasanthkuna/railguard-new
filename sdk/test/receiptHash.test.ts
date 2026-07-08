import { describe, expect, it } from 'vitest';
import { sha256, toBytes } from 'viem';
import {
  hashReceiptPayload,
  verifyReceiptHash,
  verifyReceiptSignature,
  type ReceiptPayload,
} from '../src/eip712.js';

// Canonical JSON from Go json.Marshal(receipt.Payload) — keep in sync with signgate/internal/receipt/fixture_test.go
const crossLanguageReceiptJSON =
  '{"receiptVersion":"railguard.v1","decisionId":"dec_cross_lang_fixture","decision":"ALLOW","reasonCodes":["WITHIN_LIMITS"],"agentId":"agent_support_bot_1","intentHash":"0x96734b72ae38ed4166ef08446996462802dd2c7577fe608fdc0c6371a571d150","policyHash":"0x1111111111111111111111111111111111111111111111111111111111111111","chainId":84532,"token":"0x00000000000000000000000000000000000000aa","recipient":"0x0000000000000000000000000000000000000b01","amountAtomic":"100000000","allowBatch":false,"signerKeyID":"railguard-key-v1","createdAt":"2026-07-08T00:00:00Z"}';

const crossLanguageReceiptHash =
  '0x7245e104a747ec015ca02fd107a97e2cefa92f61e3db401e3e1ea3673152c022';

const fixturePayload = JSON.parse(crossLanguageReceiptJSON) as ReceiptPayload;

describe('receiptHash', () => {
  it('matches SignGate sha256 receipt hash fixture', () => {
    expect(sha256(toBytes(crossLanguageReceiptJSON))).toBe(crossLanguageReceiptHash);
    expect(hashReceiptPayload(fixturePayload)).toBe(crossLanguageReceiptHash);
    expect(verifyReceiptHash({ payload: fixturePayload, receiptHash: crossLanguageReceiptHash })).toBe(
      true
    );
  });

  it('does not double-prefix 0x on hash output', () => {
    const hash = hashReceiptPayload(fixturePayload);
    expect(hash.startsWith('0x0x')).toBe(false);
    expect(hash).toMatch(/^0x[a-f0-9]{64}$/);
  });

  it('verifies ECDSA receipt signature from SignGate fixture', async () => {
    const receiptHash =
      '0x7245e104a747ec015ca02fd107a97e2cefa92f61e3db401e3e1ea3673152c022' as const;
    const signature =
      '0x825a4e40a6a1f5a3b5fe8ed2f9f6110bf0a787a7115950e57ae65d51168477c7646de46c0a416ca855f7dcfa14c3fef91103eaac65aae157b671fe3322312a701b' as const;
    const signer = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' as const;

    expect(
      await verifyReceiptSignature({
        payload: fixturePayload,
        receiptHash,
        signature,
        expectedSigner: signer,
      })
    ).toBe(true);
  });
});
