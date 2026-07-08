import { type Hex } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

/** Signs the raw ERC-4337 userOpHash (no EIP-191 prefix), matching RailguardSessionValidator. */
export function signSessionKeyUserOp(input: {
  sessionKeyPrivateKey: Hex;
  userOpHash: Hex;
}) {
  const account = privateKeyToAccount(input.sessionKeyPrivateKey);
  return account.sign({ hash: input.userOpHash });
}
