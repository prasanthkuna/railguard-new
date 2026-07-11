# LinkedIn / X thread (copy-paste)

**Thread — 6 posts**

---

**1/6**  
I audited a 3-repo agent payment stack (x402 + smart-account hook + CDP). The bugs weren't missing validators — they were **atomicity** and **truth convergence**.

Tag: v0.1-reference  
One link: github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md

---

**2/6**  
**Mutable ALLOW:** intent hash ignored session limits. Fix: limits in canonical hash + immutable persist.

> Authorization only matters if approved facts can't change.

---

**3/6**  
**Budget TOCTOU:** sum → pay → record. Fix: `claimReplay` + `reserveBudget` → commit | release.

> Budget enforcement is a reservation, not a read.

---

**4/6**  
**Post-broadcast lie:** DB fails after CDP tx hash → status `failed` → double-pay risk. Fix: `unknown` + reconciler.

> Exception text is not financial truth.

---

**5/6**  
**FIFO reconcile:** watcher committed oldest reservation. Fix: `executionDigest` on-chain event.

> Reconcile by identity, not queue position.

---

**6/6**  
v0.1 reference impl — E2E proof, honest gaps (reorg, HSM). Not production-ready for mainnet.

Blog draft in repo: `docs/BLOG_HARDENING_AGENT_PAYMENTS.md`

If you review money-moving systems — poke holes in the state machine. 🙏
