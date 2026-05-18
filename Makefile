.PHONY: help build up down logs shell migrate seed clean

help:
	@echo "Docker commands for PC Fútbol:"
	@echo "  make build      - Build Docker images"
	@echo "  make up         - Start containers"
	@echo "  make down       - Stop containers"
	@echo "  make logs       - View container logs"
	@echo "  make shell      - Open Rails console in web container"
	@echo "  make migrate    - Run database migrations"
	@echo "  make seed       - Seed database"
	@echo "  make clean      - Remove containers and volumes"

build:
	docker-compose build

up:
	docker-compose up -d
	@echo "✓ App started at http://localhost:3000"

down:
	docker-compose down

logs:
	docker-compose logs -f

logs-web:
	docker-compose logs -f web

logs-queue:
	docker-compose logs -f solid_queue

shell:
	docker-compose exec web bundle exec rails console

migrate:
	docker-compose exec web bundle exec rake db:migrate

seed:
	docker-compose exec web bundle exec rake db:seed

fresh:
	docker-compose exec web bundle exec rake db:drop db:create db:migrate db:seed

clean:
	docker-compose down -v
	docker system prune -f

bash:
	docker-compose exec web bash
