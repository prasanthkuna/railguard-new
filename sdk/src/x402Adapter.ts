export function x402AdapterStub() {
  return {
    name: 'railguard-x402-stub',
    buildPaymentIntent: (input: unknown) => ({ input, protocol: 'x402-stub' }),
  };
}
