.PHONY: help
help: ## show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: build
build: ## build the docker image
	docker build -t legislative_calendar .

.PHONY: run
run: ## run the docker image
	docker run -p 8080:8080 --rm --init --tty legislative_calendar

.PHONY: all
all: build run ## build and run the docker image
