import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv() # This reads your .env file and makes the variables available to os.getenv()

# Airtable Configuration
# Use the NAMES of the environment variables from your .env file
AIRTABLE_API_KEY = os.getenv("AIRTABLE_API_KEY")
AIRTABLE_BASE_ID = os.getenv("AIRTABLE_BASE_ID")
AIRTABLE_TABLE_NAME = os.getenv("AIRTABLE_TABLE_NAME")

# Basic validation
if not all([AIRTABLE_API_KEY, AIRTABLE_BASE_ID, AIRTABLE_TABLE_NAME]):
    raise ValueError(
        "Missing one or more Airtable configuration values. "
        "Please ensure AIRTABLE_API_KEY, AIRTABLE_BASE_ID, and AIRTABLE_TABLE_NAME are defined in your .env file and that the .env file is in the same directory as config.py (recipe_ingestion)."
    )

# You can add other configurations here as needed, for example:
# DEFAULT_REQUEST_TIMEOUT = 10
# LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")