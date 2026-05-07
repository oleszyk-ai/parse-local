.PHONY: setup run dev clean docker

# One-command setup + run
all: setup run

setup:
	@chmod +x setup.sh 2>/dev/null; true
	@bash setup.sh

run:
	@source .venv/bin/activate && python -m app.main

dev:
	@source .venv/bin/activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

clean:
	rm -rf .venv __pycache__ app/__pycache__
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true

clean-all: clean
	rm -rf models/*.gguf

docker:
	docker-compose up --build

docker-down:
	docker-compose down