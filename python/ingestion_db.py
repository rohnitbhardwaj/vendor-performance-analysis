
import pandas as pd
import os
from sqlalchemy import create_engine
import logging
import time

# Create logs folder if it doesn't exist
os.makedirs("logs", exist_ok=True)

# Configure logging to track ingestion activities
logging.basicConfig(
    filename="logs/ingestion_db.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    filemode="a"
)

# Create SQL Server database connection
engine = create_engine(
    "mssql+pyodbc://YOUR_SERVER/inventory"
    "?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes",
    fast_executemany=True
)

# Load DataFrame into SQL Server table
def ingest_db(df, table_name, engine):
    df.to_sql(table_name, con=engine, if_exists='replace',
              index=False, chunksize=10000)

# Define folder containing CSV files
folder = r'path/to/data'


# Read CSV files and ingest them into the database
def load_raw_data():
    start = time.time()

    # Iterate through all CSV files in the folder
    for file in os.listdir(folder):
        if file.endswith('.csv'):
            df = pd.read_csv(os.path.join(folder, file))

            # Log ingestion activity and load data into SQL Server
            logging.info(f'Ingesting {file} in db')
            ingest_db(df, file[:-4], engine)

    # Calculate total ingestion time in minutes
    end = time.time()
    time_taken = (end - start)/60

    # Log ingestion completion and execution time
    logging.info('=============Ingestion Completed================')
    logging.info(f'Total_Time Taken: {time_taken} minutes')

# =============================================================================
