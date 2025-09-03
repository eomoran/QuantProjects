Contributing to QuantProjects

Thanks for helping out! This guide explains how we work so contributions are smooth and conflict‑free.

⸻

📦 Prerequisites
	•	Python ≥ 3.10
	•	Git, GitHub account
	•	Recommended: create a virtual env (python -m venv .venv && source .venv/bin/activate)

Install dev tooling:

pip install -e .[dev]
pre-commit install
pre-commit run --all-files

Run tests:

pytest


⸻

🌳 Branching model
	•	Main branch: main (protected)
	•	Feature branches: short‑lived, scoped by area
	•	feat/data/<short-desc>
	•	feat/model/<short-desc>
	•	feat/backtest/<short-desc>
	•	Other types: fix/*, chore/*, docs/*, refactor/*

Create a branch:

git switch -c feat/model/add-lstm-baseline

Keep up‑to‑date (rebase preferred):

git fetch origin && git rebase origin/main


⸻

🧾 Commit messages (Conventional Commits)

Format: type(scope): summary

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore.

Examples:

feat(data): add Yahoo ingestion client
fix(backtest): correct leakage in walk-forward split
chore: enable mypy strict mode in CI


⸻

🧰 Code style & quality
	•	Formatting: black, isort
	•	Linting: ruff
	•	Typing: mypy --strict (configured in pyproject.toml)
	•	Tests: pytest (mark slow tests with @pytest.mark.slow)

All of the above run via pre-commit and CI. Please fix issues locally before pushing.

Useful commands:

pre-commit run --all-files
ruff check src tests --fix
black src tests
pytest -m "not slow" -q
mypy src


⸻

🧩 Project layout & contracts

src/
  qp_data/       # dataset gathering & preprocessing
    schema.py    # Data→Model contract (columns, dtypes, validation)
  qp_model/      # model interfaces & training
    interfaces.py# Model→Backtest contract (Protocols)
  qp_backtest/   # cross‑validation & backtesting engines

Do not change schema.py or interfaces.py lightly. If you must, include:
	1.	a clear migration note in the PR description, and 2) tests that demonstrate compatibility or new behavior.

⸻

🔐 Secrets & data policy
	•	Never commit secrets (API keys, tokens). Use .env (gitignored) and document required variables in README.md.
	•	Data files belong in data/ and are gitignored. Use Git LFS or DVC only if explicitly agreed.
	•	Include small synthetic fixtures under tests/fixtures/ (OK to commit).

⸻

📓 Notebooks
	•	Notebooks are optional and should be kept out of core flows.
	•	Prefer Jupytext (paired .py) and enable nbdime locally to reduce merge conflicts.
	•	One notebook per person per task; export final plots/results to code where possible.

⸻

🔁 Pull requests
	1.	Ensure branch is rebased on main and tests pass locally.
	2.	Add/adjust tests for your change.
	3.	Keep PRs focused (≤ ~300 lines changed when possible).
	4.	Fill out the PR description with context, approach, and trade‑offs.
	5.	CI must be green. CODEOWNERS reviewer(s) must approve.

Open PR:

git push -u origin <your-branch>
# then open the PR on GitHub


⸻

👀 Reviews & CODEOWNERS
	•	CODEOWNERS routes reviews to the right person(s). For now the default owner is @eomoran.
	•	Please respond to reviews with either code changes or rationale.
	•	Reviewers: focus on correctness, test coverage, contracts, and clarity.

⸻

🧪 Testing guidance
	•	Unit tests live in tests/ mirroring package paths.
	•	Mark slow/integration tests with @pytest.mark.slow so CI can run the fast suite by default.
	•	Use src/qp_data/schema.py::example_fixture where a tiny deterministic dataset helps.

⸻

🚢 Merging strategy
	•	Prefer squash merge to keep history tidy.
	•	After merge, delete the feature branch.

⸻

🆘 Getting help

Open a GitHub Issue with a clear title and reproduction steps, or start a discussion. For urgent build issues, ping the code owner listed in CODEOWNERS.
