.PHONY: lint format format-check test pages-build check

lint:
	find . -type f -name '*.sh' -not -path './.git/*' -print0 | xargs -0 shellcheck

format:
	shfmt -w -i 2 -ci -sr .

format-check:
	shfmt -d -i 2 -ci -sr .

# Discover and run each tests/*_test.sh in parallel (-P4).
# Per-file contracts: see tests/README.md.
test:
	find tests -maxdepth 1 -name '*_test.sh' -print0 | xargs -0 -n1 -P4 bash

pages-build:
	bash docs/build.sh .tmp/pages

check: lint test
