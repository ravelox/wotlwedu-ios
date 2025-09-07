.PHONY: project open generate-api clean-api

project:
	xcodegen generate

open: project
	@if command -v xed >/dev/null 2>&1; then \
		xed . ; \
	else \
		open -a "Xcode" WotlweduClient.xcodeproj ; \
	fi

# --- OpenAPI codegen (requires Docker) ---
generate-api:
	docker run --rm -v $$(pwd):/local openapitools/openapi-generator-cli:v7.8.0 generate \
		-c /local/Tools/openapi-swift-config.yaml

clean-api:
	rm -rf Generated/WotlweduAPI