.PHONY: frontend-test backend-test test build-images run-local smoke terraform-fmt terraform-validate validate
frontend-test:
	bash scripts/frontend-test.sh
backend-test:
	bash scripts/backend-test.sh
test: frontend-test backend-test
build-images:
	bash scripts/build-images.sh
run-local:
	bash scripts/run-local.sh
smoke:
	bash scripts/smoke-test.sh
terraform-fmt:
	terraform fmt -recursive infra
terraform-validate:
	terraform -chdir=infra/modules/ecs-fargate-webapp init -backend=false
	terraform -chdir=infra/modules/ecs-fargate-webapp validate
validate:
	bash scripts/validate.sh
