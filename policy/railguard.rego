package railguard

import rego.v1

default allow = false

default decision = "BLOCK"
default reason_codes = ["POLICY_DENIED"]

allowed_agents := {
	"agent_support_bot_1",
}

allowed_tokens := {
	"0x00000000000000000000000000000000000000aa",
}

blocked_tokens := {
	"0x00000000000000000000000000000000000000bb",
}

token_allowed if {
	input.token in allowed_tokens
}

token_allowed if {
	input.agentId in allowed_agents
	regex.match(`^0x[0-9a-f]{40}$`, input.token)
	not input.token in blocked_tokens
}

railguard = {
	"decision": decision,
	"reason_codes": reason_codes,
}

block_reasons contains "SANCTIONS_HIT" if {
	input.risk.sanctionsHit == true
}

block_reasons contains "WRONG_CHAIN" if {
	input.chainId != 84532
}

block_reasons contains "UNKNOWN_AGENT" if {
	not input.agentId in allowed_agents
}

block_reasons contains "TOKEN_NOT_ALLOWED" if {
	not token_allowed
}

block_reasons contains "HIGH_RISK_RECIPIENT" if {
	input.risk.recipientRiskScore > 80
}

block_reasons contains "UNKNOWN_DOMAIN" if {
	input.resource.domain == "blocked.vendor"
}

block_reasons contains "AMOUNT_EXCEEDS_MAX_PER_TRANSFER" if {
	input.limits.maxPerTransfer != ""
	to_number(input.amountAtomic) > to_number(input.limits.maxPerTransfer)
}

block_reasons contains "AMOUNT_EXCEEDS_MAX_TOTAL_SPEND" if {
	input.limits.maxTotalSpend != ""
	to_number(input.amountAtomic) > to_number(input.limits.maxTotalSpend)
}

block_reasons contains "TARGET_NOT_EQUAL_TOKEN" if {
	input.execution.allowedTarget != ""
	input.execution.allowedTarget != input.token
}

block_reasons contains "UNSUPPORTED_SELECTOR" if {
	input.execution.selector != ""
	input.execution.selector != "0xa9059cbb"
}

block_reasons contains "BATCH_NOT_ALLOWED" if {
	input.execution.isBatch == true
	input.execution.allowBatch == false
}

block_reasons contains "SESSION_NOT_VALID" if {
	input.execution.sessionValidNow == false
}

decision := "BLOCK" if {
	count(block_reasons) > 0
}

reason_codes := sort(block_reasons) if {
	count(block_reasons) > 0
}

decision := "ALLOW" if {
	count(block_reasons) == 0
	input.chainId == 84532
	input.agentId in allowed_agents
	token_allowed
	not input.risk.sanctionsHit
	input.risk.recipientRiskScore <= 80
	input.resource.domain != "blocked.vendor"
	input.amountAtomic != ""
	to_number(input.amountAtomic) > 0
	within_transfer_limit
	within_total_limit
	execution_constraints_ok
}

reason_codes := ["WITHIN_LIMITS"] if {
	decision == "ALLOW"
}

within_transfer_limit if {
	input.limits.maxPerTransfer == ""
}

within_transfer_limit if {
	input.limits.maxPerTransfer != ""
	to_number(input.amountAtomic) <= to_number(input.limits.maxPerTransfer)
}

within_total_limit if {
	input.limits.maxTotalSpend == ""
}

within_total_limit if {
	input.limits.maxTotalSpend != ""
	to_number(input.amountAtomic) <= to_number(input.limits.maxTotalSpend)
}

execution_constraints_ok if {
	input.execution.allowedTarget == ""
}

execution_constraints_ok if {
	input.execution.allowedTarget == input.token
}

execution_constraints_ok if {
	input.execution.selector == ""
}

execution_constraints_ok if {
	input.execution.selector == "0xa9059cbb"
}

execution_constraints_ok if {
	not input.execution.isBatch
}

execution_constraints_ok if {
	input.execution.allowBatch == true
}

execution_constraints_ok if {
	input.execution.sessionValidNow != false
}
