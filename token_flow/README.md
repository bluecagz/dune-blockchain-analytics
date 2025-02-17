# Dune Sandbox Project

This project uses a query from Dune to pull in the transfers of PAXG or any other ETH token to create a Sankey diagram to understand the activity flow of where tokens are going and leaving.

## Installation

To set up the project, follow these steps:

1. Clone the repository:
    ```sh
    git clone <repository-url>
    cd dune-sandbox
    ```

2. Run the setup script to install dependencies and set up the environment:
    ```sh
    ./setup.sh
    ```

## Usage

1. Activate the virtual environment:
    ```sh
    poetry shell
    ```

2. Start the Jupyter Notebook server:
    ```sh
    poetry run jupyter notebook
    ```

3. Open the `paxg_token_flow.ipynb` notebook in the `notebooks` directory and run the cells to generate the Sankey diagram.
