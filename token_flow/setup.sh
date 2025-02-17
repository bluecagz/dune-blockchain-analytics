echo "Setting up the project..."
echo "Setting up Python environment with Poetry..."

# Install Poetry if not already installed
curl -sSL https://install.python-poetry.org | python3 -

# Add Poetry to PATH
export PATH="$HOME/.local/bin:$PATH"

# Install dependencies using Poetry
poetry install

# Activate the Poetry environment
poetry shell

# Install the IPython kernel package
poetry run python -m ipykernel install --user --name=dune-sandbox --display-name "Python (dune-sandbox)"

echo "Project setup complete."
