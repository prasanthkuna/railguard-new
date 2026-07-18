.PHONY: setup contracts-deps contracts-build contracts-test signgate-test opa-test sdk-test ci dev demo e2e deploy-anvil failure-lab

setup: contracts-deps
	cd signgate && go mod tidy
	cd sdk && npm install

contracts-deps:
	cd contracts && forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts

contracts-build:
	cd contracts && forge build

contracts-test:
	cd contracts && forge test -vvv

signgate-test:
	cd signgate && go test ./...

opa-test:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -File scripts/run-opa-tests.ps1
else
	bash scripts/run-opa-tests.sh 2>/dev/null || powershell -NoProfile -File scripts/run-opa-tests.ps1
endif

sdk-test:
	cd sdk && npm test

demo:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -File scripts/demo-onchain.ps1
else
	bash scripts/demo-onchain.sh 2>/dev/null || powershell -NoProfile -File scripts/demo-onchain.ps1
endif

e2e:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -File scripts/e2e-happy-path.ps1
else
	bash scripts/e2e-happy-path.sh 2>/dev/null || powershell -NoProfile -File scripts/e2e-happy-path.ps1
endif

e2e-smoke:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -File scripts/e2e-smoke.ps1
else
	bash scripts/e2e-smoke.sh 2>/dev/null || powershell -NoProfile -File scripts/e2e-smoke.ps1
endif

failure-lab:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -File scripts/failure-lab.ps1
else
	bash scripts/failure-lab.sh
endif

deploy-anvil:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -File scripts/deploy-anvil.ps1
else
	bash scripts/deploy-anvil.sh 2>/dev/null || powershell -NoProfile -File scripts/deploy-anvil.ps1
endif

ci: contracts-build contracts-test signgate-test opa-test sdk-test

dev:
	docker compose up --build
