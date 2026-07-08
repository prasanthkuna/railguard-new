package railguard_test

import rego.v1

test_allow_vendor if {
	result := data.railguard with input as {
		"agentId": "agent_support_bot_1",
		"account": "0x1",
		"chainId": 84532,
		"token": "0x00000000000000000000000000000000000000aa",
		"recipient": "0xb01",
		"amountAtomic": "100000000",
		"resource": {"method": "POST", "domain": "api.vendor.com", "path": "/v1/report"},
		"risk": {"recipientRiskScore": 10, "sanctionsHit": false},
		"limits": {"maxPerTransfer": "100000000", "maxTotalSpend": "500000000"},
	}
	result.decision == "ALLOW"
}

test_block_sanctions if {
	result := data.railguard with input as {
		"agentId": "agent_support_bot_1",
		"chainId": 84532,
		"token": "0x00000000000000000000000000000000000000aa",
		"amountAtomic": "1",
		"risk": {"recipientRiskScore": 10, "sanctionsHit": true},
		"resource": {"domain": "api.vendor.com"},
	}
	result.decision == "BLOCK"
}

test_block_unknown_agent if {
	result := data.railguard with input as {
		"agentId": "unknown",
		"chainId": 84532,
		"token": "0x00000000000000000000000000000000000000aa",
		"amountAtomic": "1",
		"risk": {"recipientRiskScore": 10, "sanctionsHit": false},
		"resource": {"domain": "api.vendor.com"},
	}
	result.decision == "BLOCK"
}
