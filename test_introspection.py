#!/usr/bin/env python3
"""
Test file to demonstrate invoke.nvim introspection capabilities.
This file contains sample tasks that can be discovered via Python introspection.
"""

from invoke import task
from pathlib import Path
import subprocess
import sys


@task
def hello(c, name="World"):
    """Say hello to someone."""
    print(f"Hello, {name}!")


@task
def test(c, verbose=False):
    """Run the test suite."""
    cmd = "python -m pytest"
    if verbose:
        cmd += " -v"
    c.run(cmd)


@task
def build(c, clean=False):
    """Build the project."""
    if clean:
        c.run("rm -rf build/ dist/ *.egg-info/")
    c.run("python setup.py build")


@task
def install(c, dev=False):
    """Install the package."""
    if dev:
        c.run("pip install -e .")
    else:
        c.run("pip install .")


@task
def lint(c):
    """Run linting tools."""
    c.run("flake8 .")
    c.run("black --check .")
    c.run("isort --check-only .")


@task
def format(c):
    """Format code using black and isort."""
    c.run("black .")
    c.run("isort .")


@task
def docs(c, serve=False):
    """Build documentation."""
    c.run("sphinx-build -b html docs/ docs/_build/html")
    if serve:
        c.run("python -m http.server 8000 --directory docs/_build/html")


@task
def clean(c):
    """Clean build artifacts and temporary files."""
    c.run("rm -rf build/ dist/ *.egg-info/ __pycache__/ .pytest_cache/")
    c.run("find . -name '*.pyc' -delete")


@task
def release(c, version):
    """Create a new release."""
    c.run(f"git tag v{version}")
    c.run("git push --tags")
    c.run("python setup.py sdist bdist_wheel")
    c.run("twine upload dist/*")


@task
def docker_build(c, tag="latest"):
    """Build Docker image."""
    c.run(f"docker build -t myapp:{tag} .")


@task
def docker_run(c, tag="latest", port=8000):
    """Run Docker container."""
    c.run(f"docker run -p {port}:8000 myapp:{tag}")


@task
def deploy(c, environment="staging"):
    """Deploy to specified environment."""
    if environment == "production":
        c.run("echo 'Deploying to production...'")
        c.run("kubectl apply -f k8s/production/")
    else:
        c.run("echo 'Deploying to staging...'")
        c.run("kubectl apply -f k8s/staging/")


@task
def backup(c, database="main"):
    """Create database backup."""
    c.run(f"pg_dump {database} > backup_{database}_$(date +%Y%m%d_%H%M%S).sql")


@task
def monitor(c, duration=60):
    """Monitor system resources."""
    c.run(f"htop -d {duration}")


@task
def setup_dev(c):
    """Setup development environment."""
    c.run("pip install -r requirements-dev.txt")
    c.run("pre-commit install")
    c.run("cp .env.example .env")


@task
def migrate(c, direction="up"):
    """Run database migrations."""
    if direction == "up":
        c.run("alembic upgrade head")
    elif direction == "down":
        c.run("alembic downgrade -1")
    else:
        c.run("alembic current")


@task
def seed(c, data="test"):
    """Seed database with sample data."""
    c.run(f"python scripts/seed_{data}_data.py")


@task
def benchmark(c, iterations=1000):
    """Run performance benchmarks."""
    c.run(f"python -m pytest tests/benchmark/ -k test_performance --benchmark-only --benchmark-iterations={iterations}")


@task
def security_scan(c):
    """Run security vulnerability scan."""
    c.run("bandit -r .")
    c.run("safety check")


@task
def coverage(c, html=False):
    """Run tests with coverage reporting."""
    c.run("coverage run -m pytest")
    c.run("coverage report")
    if html:
        c.run("coverage html")


@task
def package(c, format="wheel"):
    """Package the application."""
    if format == "wheel":
        c.run("python setup.py bdist_wheel")
    elif format == "source":
        c.run("python setup.py sdist")
    else:
        c.run("python setup.py bdist_wheel sdist")


@task
def validate(c):
    """Validate project configuration and dependencies."""
    c.run("python -c 'import ast; ast.parse(open(\"setup.py\").read())'")
    c.run("python -m pip check")
    c.run("python -c 'import pkg_resources; pkg_resources.require(open(\"requirements.txt\").readlines())'")


@task
def update_deps(c):
    """Update project dependencies."""
    c.run("pip install --upgrade pip")
    c.run("pip install --upgrade -r requirements.txt")
    c.run("pip freeze > requirements.txt")


@task
def health_check(c):
    """Run health checks on the application."""
    c.run("python -c 'import requests; requests.get(\"http://localhost:8000/health\")'")
    c.run("python -c 'import psutil; print(f\"CPU: {psutil.cpu_percent()}%, Memory: {psutil.virtual_memory().percent}%\")'")


@task
def logs(c, service="app", lines=100):
    """Show application logs."""
    c.run(f"docker logs --tail {lines} {service}")


@task
def restart(c, service="app"):
    """Restart a service."""
    c.run(f"docker restart {service}")


@task
def status(c):
    """Show status of all services."""
    c.run("docker ps")
    c.run("kubectl get pods")


@task
def backup_config(c):
    """Backup configuration files."""
    c.run("tar -czf config_backup_$(date +%Y%m%d_%H%M%S).tar.gz config/") 