QuantProjects

A collaborative research toolkit for quantitative finance.
This repository is structured for modular work across three main areas:
    •    Dataset Gathering (src/qp_data/)
Collect, clean, and validate datasets (e.g. market data, alternative data).
    •    Model Design (src/qp_model/)
Define predictive models and training loops.
    •    Cross-Validation & Backtesting (src/qp_backtest/)
Robust evaluation pipelines (e.g. walk-forward, purged CV).

⸻

🚀 Getting Started

1. Clone the repo

git clone git@github.com:YOUR-USERNAME/QuantProjects.git
cd QuantProjects

2. Install dependencies

We use a PEP 621 pyproject.toml.
For development:

python -m pip install --upgrade pip
pip install -e .[dev]

3. Enable pre-commit hooks

pre-commit install
pre-commit run --all-files

4. Run tests

pytest


⸻

📂 Project Structure

QuantProjects/
├─ src/
│  ├─ qp_data/        # Data ingestion & preprocessing
│  │   └─ schema.py   # Dataset contracts
│  ├─ qp_model/       # Model definitions & training
│  │   └─ interfaces.py
│  └─ qp_backtest/    # Backtesting & CV logic
├─ tests/             # Unit tests
├─ .pre-commit-config.yaml
├─ pyproject.toml
└─ .github/workflows/ci.yml


⸻

🛠️ Development Workflow
    1.    Branching
    •    Branch off main using naming like:
    •    feat/data/*
    •    feat/model/*
    •    feat/backtest/*
    2.    Contracts
    •    qp_data/schema.py defines what data looks like.
    •    qp_model/interfaces.py defines how models must behave.
    •    Backtesting relies only on these contracts → minimizes conflicts.
    3.    Pull Requests
    •    Keep PRs small (≤300 lines).
    •    All PRs require tests and must pass CI before merging.

⸻

✅ CI / Code Quality
    •    Lint/Format: black, ruff, isort
    •    Type Checking: mypy
    •    Testing: pytest
    •    CI: GitHub Actions runs on every push/PR to main

⸻

🤝 Contributing
    1.    Fork the repo (if external) or branch off main (if you have access).
    2.    Follow commit convention:

feat(data): add Yahoo Finance scraper
fix(model): correct LSTM loss function
chore(backtest): improve logging


    3.    Submit a Pull Request → code review required.

⸻

📜 License

MIT License © Quant Enthusiasts
