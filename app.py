import streamlit as st

import os
from dotenv import load_dotenv
import mysql.connector

import re

# Load .env variables
load_dotenv()

# Get DB credentials from environment variables
db_config = {
    "host": os.getenv("MYSQL_HOST"),
    "port": int(os.getenv("MYSQL_PORT", 3306)),  # default 3306 if not set
    "user": os.getenv("MYSQL_USER"),
    "password": os.getenv("MYSQL_PASSWORD"),
    "database": os.getenv("MYSQL_DATABASE")
}

database_schema = f"""
-- ==========================
-- 1. Table Definitions
-- ==========================

-- Doctor Table
CREATE TABLE Doctor (
    AadharID CHAR(12) PRIMARY KEY,
    Name VARCHAR(100),
    Specialty VARCHAR(100),
    YearsOfExperience INT
);

-- Patient Table
CREATE TABLE Patient (
    AadharID CHAR(12) PRIMARY KEY,
    Name VARCHAR(100),
    Address VARCHAR(200),
    BirthDate DATE,
    PrimaryPhysicianID CHAR(12),
    FOREIGN KEY (PrimaryPhysicianID) REFERENCES Doctor(AadharID)
);

-- PharmaceuticalCompany Table
CREATE TABLE PharmaceuticalCompany (
    Name VARCHAR(100) PRIMARY KEY,
    PhoneNo VARCHAR(15)
);

-- Drug Table
CREATE TABLE Drug (
    TradeName VARCHAR(100),
    Formula TEXT,
    CompanyName VARCHAR(100),
    PRIMARY KEY (TradeName, CompanyName),
    FOREIGN KEY (CompanyName) REFERENCES PharmaceuticalCompany(Name) ON DELETE CASCADE
);

-- Pharmacy Table
CREATE TABLE Pharmacy (
    Name VARCHAR(100) PRIMARY KEY,
    Address VARCHAR(200),
    PhoneNo VARCHAR(15)
);

-- Sells Table
CREATE TABLE Sells (
    PharmacyName VARCHAR(100),
    TradeName VARCHAR(100),
    CompanyName VARCHAR(100),
    Price DECIMAL(10,2),
    PRIMARY KEY (PharmacyName, TradeName, CompanyName),
    FOREIGN KEY (PharmacyName) REFERENCES Pharmacy(Name),
    FOREIGN KEY (TradeName, CompanyName) REFERENCES Drug(TradeName, CompanyName)
);

-- Prescription Table
CREATE TABLE Prescription (
    DoctorID CHAR(12),
    PatientID CHAR(12),
    Date DATE,
    PRIMARY KEY (DoctorID, PatientID, Date),
    FOREIGN KEY (DoctorID) REFERENCES Doctor(AadharID),
    FOREIGN KEY (PatientID) REFERENCES Patient(AadharID)
);

-- PrescriptionDrug Table
CREATE TABLE PrescriptionDrug (
    DoctorID CHAR(12),
    PatientID CHAR(12),
    Date DATE,
    TradeName VARCHAR(100),
    CompanyName VARCHAR(100),
    Quantity INT,
    PRIMARY KEY (DoctorID, PatientID, Date, TradeName, CompanyName),
    FOREIGN KEY (DoctorID, PatientID, Date) REFERENCES Prescription(DoctorID, PatientID, Date),
    FOREIGN KEY (TradeName, CompanyName) REFERENCES Drug(TradeName, CompanyName)
);

-- Contract Table
CREATE TABLE Contract (
    PharmaCompanyName VARCHAR(100),
    PharmacyName VARCHAR(100),
    StartDate DATE,
    EndDate DATE,
    Content TEXT,
    SupervisorAadharID CHAR(12),
    PRIMARY KEY (PharmaCompanyName, PharmacyName, StartDate),
    FOREIGN KEY (PharmaCompanyName) REFERENCES PharmaceuticalCompany(Name),
    FOREIGN KEY (PharmacyName) REFERENCES Pharmacy(Name),
    FOREIGN KEY (SupervisorAadharID) REFERENCES Doctor(AadharID)
);


"""



def query_to_result(user_query):
    import ollama

    prompt = f"""
    You are an expert SQL query generator. Given a natural language request about data from the database, write a valid MySQL SQL query that answers the request.

    Instructions:  
    - Only generate SELECT and SHOW queries.  
    - Use proper SQL syntax for MySQL.  
    - Make sure to handle filtering, sorting, and aggregation as per the request.  
    - If the request is ambiguous, ask for clarification or make a reasonable assumption.  
    - Don't include explanations, only output the SQL query.

    Example input:  
    "Show me the names and emails of users who signed up after January 1, 2023."

    Expected output:  
    SELECT name, email FROM users WHERE signup_date > '2023-01-01';

    Database scheme is also provided to make a better analysis of the user's needs.
    Database schema: {database_schema}

    The user's query: {user_query}

    """

    response = ollama.chat(
        model='qwen3:0.6b',
        messages=[{'role': 'user', 'content': prompt}]
    )

    raw_content = response['message']['content']

    # Remove all <think>...</think> tags and their content
    clean_content = re.sub(r'<think>.*?</think>', '', raw_content, flags=re.DOTALL)

    clean_content = clean_content.strip()

    generated_query = clean_content
    
    return raw_content

def clean_ollama(raw_content):
    # Remove all <think>...</think> tags and their content
    clean_content = re.sub(r'<think>.*?</think>', '', raw_content, flags=re.DOTALL)

    clean_content = clean_content.strip()

    generated_query = clean_content
    
    return generated_query


def gen_query_to_sql_db(generated_query):
    # Connect to MySQL
    try:
        conn = mysql.connector.connect(**db_config)
        print("Connected to MySQL database!\n")

        cursor = conn.cursor()
        cursor.execute(generated_query)
        
        # Get column names and results
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        results = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        # Convert to list of dicts for better display
        results_dicts = [dict(zip(columns, row)) for row in results]
        return {'columns': columns, 'results': results_dicts}

    except mysql.connector.Error as err:
        print("Error:", err)
        return {'error': str(err)}

st.title("SQL LLM")

prompt = st.text_area("Enter your prompt:")

if st.button("Fetch"):
    if prompt.strip() == "":
        st.warning("Please enter a prompt.")
    else:
        with st.spinner("Thinking..."):
            raw_content = query_to_result(prompt)
            generated_query = clean_ollama(raw_content)
            query_results = gen_query_to_sql_db(generated_query)
            
            st.markdown("### Thinking Process:")
            st.text(raw_content)

            st.success("Done!")
            st.markdown("### Generated SQL Query:")
            st.code(generated_query, language="sql")
            


            st.markdown("### Query Results:")
            if 'error' in query_results:
                st.error(f"Error executing query: {query_results['error']}")
            else:
                
                # Display as a dataframe if we have results
                if query_results['results']:
                    import pandas as pd
                    df = pd.DataFrame(query_results['results'])
                    st.dataframe(df, use_container_width=True)
                else:
                    st.info("Query executed successfully but returned no results.")
