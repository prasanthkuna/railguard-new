.PHONY: setup contracts-deps contracts-build contracts-test signgate-test opa-test sdk-test ci dev demo e2e deploy-anvil

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
	powershell -File scripts/run-opa-tests.ps1

sdk-test:
	cd sdk && npm test

demo:
	powershell -File scripts/demo-onchain.ps1

e2e:
	powershell -File scripts/e2e-happy-path.ps1

e2e-smoke:
	powershell -File scripts/e2e-smoke.ps1

deploy-anvil:
	powershell -File scripts/deploy-anvil.ps1

ci: contracts-build contracts-test signgate-test opa-test sdk-test

dev:
	docker compose up --build
