export function agentkitAdapterStub() {
  return {
    name: 'railguard-agentkit-stub',
    evaluateIntent: async (intent: unknown) => ({ decision: 'ALLOW', intent }),
  };
}
