create database sample;
show databases;
use sample;

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




-- ==========================
-- 2. Triggers
-- ==========================

-- 1. Prevent deleting a doctor who has assigned patients
CREATE TRIGGER Prevent_Doctor_Without_Patients
BEFORE DELETE ON Doctor
FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM Patient
    WHERE PrimaryPhysicianID = OLD.AadharID;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete doctor with assigned patients.';
    END IF;
END;


-- Prevent pharmacy from having <10 drugs
-- CREATE TRIGGER Check_Min_Drugs_Per_Pharmacy
-- BEFORE DELETE ON Sells
-- FOR EACH ROW
-- BEGIN
--     DECLARE v_count INT;
--     SELECT COUNT(*) INTO v_count
--     FROM Sells
--     WHERE PharmacyName = OLD.PharmacyName
--       AND NOT (TradeName = OLD.TradeName AND CompanyName = OLD.CompanyName);

--     IF v_count < 10 THEN
--         SIGNAL SQLSTATE '45000'
--         SET MESSAGE_TEXT = 'A pharmacy must sell at least 10 drugs.';
--     END IF;
-- END;

-- ==========================
-- 3. Indexes
-- ==========================
CREATE INDEX idx_patient_physician ON Patient(PrimaryPhysicianID);
CREATE INDEX idx_prescription_patient ON Prescription(PatientID);
CREATE INDEX idx_contract_supervisor ON Contract(SupervisorAadharID);

-- ==========================
-- 4. Stored Procedures
-- ================================
-- Doctor CRUD Procedures
-- ================================

-- Create Doctor
DROP PROCEDURE IF EXISTS add_doctor;
CREATE PROCEDURE add_doctor (
    IN p_aadhar CHAR(12),
    IN p_name VARCHAR(100),
    IN p_specialty VARCHAR(100),
    IN p_years INT
)
BEGIN
    INSERT INTO Doctor (AadharID, Name, Specialty, YearsOfExperience)
    VALUES (p_aadhar, p_name, p_specialty, p_years);
END;

-- Update Doctor
DROP PROCEDURE IF EXISTS update_doctor;
CREATE PROCEDURE update_doctor (
    IN p_aadhar CHAR(12),
    IN p_name VARCHAR(100),
    IN p_specialty VARCHAR(100),    
    IN p_years INT
)
BEGIN
    UPDATE Doctor 
    SET Name = p_name, 
        Specialty = p_specialty, 
        YearsOfExperience = p_years
    WHERE AadharID = p_aadhar;
END;

-- Delete Doctor
DROP PROCEDURE IF EXISTS delete_doctor;
CREATE PROCEDURE delete_doctor (
    IN p_aadhar CHAR(12)
)
BEGIN
    DELETE FROM Doctor WHERE AadharID = p_aadhar;
END;

-- ================================
-- Patient CRUD Procedures
-- ================================

-- Add Patient
DROP PROCEDURE IF EXISTS add_patient;
CREATE PROCEDURE add_patient (
    IN p_aadhar CHAR(12),
    IN p_name VARCHAR(100),
    IN p_address VARCHAR(200),
    IN p_birthdate DATE,
    IN p_doctor CHAR(12)
)
BEGIN
    INSERT INTO Patient (AadharID, Name, Address, BirthDate, PrimaryPhysicianID)
    VALUES (p_aadhar, p_name, p_address, p_birthdate, p_doctor);
END;

-- Update Patient
DROP PROCEDURE IF EXISTS update_patient;
CREATE PROCEDURE update_patient (
    IN p_aadhar CHAR(12),
    IN p_name VARCHAR(100),
    IN p_address VARCHAR(200),
    IN p_birthdate DATE,
    IN p_doctor CHAR(12)
)
BEGIN
    UPDATE Patient 
    SET Name = p_name,
        Address = p_address,
        BirthDate = p_birthdate,
        PrimaryPhysicianID = p_doctor
    WHERE AadharID = p_aadhar;
END;

-- Delete Patient
DROP PROCEDURE IF EXISTS delete_patient;
CREATE PROCEDURE delete_patient (
    IN p_aadhar CHAR(12)
)
BEGIN
    DELETE FROM Patient WHERE AadharID = p_aadhar;
END;

-- ================================
-- PharmaceuticalCompany CRUD Procedures
-- ================================

-- Create PharmaceuticalCompany
DROP PROCEDURE IF EXISTS add_pharma_company;
CREATE PROCEDURE add_pharma_company (
    IN p_name VARCHAR(100),
    IN p_phone VARCHAR(15)
)
BEGIN
    INSERT INTO PharmaceuticalCompany (Name, PhoneNo)
    VALUES (p_name, p_phone);
END;

-- Update PharmaceuticalCompany
DROP PROCEDURE IF EXISTS update_pharma_company;
CREATE PROCEDURE update_pharma_company (
    IN p_name VARCHAR(100),
    IN p_phone VARCHAR(15)
)
BEGIN
    UPDATE PharmaceuticalCompany
    SET PhoneNo = p_phone
    WHERE Name = p_name;
END;

-- Delete PharmaceuticalCompany
DROP PROCEDURE IF EXISTS delete_pharma_company;
CREATE PROCEDURE delete_pharma_company (
    IN p_name VARCHAR(100)
)
BEGIN
    DELETE FROM PharmaceuticalCompany WHERE Name = p_name;
END;

-- ================================
-- Drug CRUD Procedures
-- ================================

-- Create Drug
DROP PROCEDURE IF EXISTS add_drug;
CREATE PROCEDURE add_drug (
    IN p_trade_name VARCHAR(100),
    IN p_formula TEXT,
    IN p_company_name VARCHAR(100)
)
BEGIN
    INSERT INTO Drug (TradeName, Formula, CompanyName)
    VALUES (p_trade_name, p_formula, p_company_name);
END;

-- Update Drug
DROP PROCEDURE IF EXISTS update_drug;
CREATE PROCEDURE update_drug (
    IN p_trade_name VARCHAR(100),
    IN p_company_name VARCHAR(100),
    IN p_formula TEXT
)
BEGIN
    UPDATE Drug
    SET Formula = p_formula
    WHERE TradeName = p_trade_name AND CompanyName = p_company_name;
END;

-- Delete Drug
DROP PROCEDURE IF EXISTS delete_drug;
CREATE PROCEDURE delete_drug (
    IN p_trade_name VARCHAR(100),
    IN p_company_name VARCHAR(100)
)
BEGIN
    DELETE FROM Drug 
    WHERE TradeName = p_trade_name AND CompanyName = p_company_name;
END;

-- ================================
-- Pharmacy CRUD Procedures
-- ================================

-- Create Pharmacy
DROP PROCEDURE IF EXISTS add_pharmacy;
CREATE PROCEDURE add_pharmacy (
    IN p_name VARCHAR(100),
    IN p_address VARCHAR(200),
    IN p_phone VARCHAR(15)
)
BEGIN
    INSERT INTO Pharmacy (Name, Address, PhoneNo)
    VALUES (p_name, p_address, p_phone);
END;

-- Update Pharmacy
DROP PROCEDURE IF EXISTS update_pharmacy;
CREATE PROCEDURE update_pharmacy (
    IN p_name VARCHAR(100),
    IN p_address VARCHAR(200),
    IN p_phone VARCHAR(15)
)
BEGIN
    UPDATE Pharmacy
    SET Address = p_address,
        PhoneNo = p_phone
    WHERE Name = p_name;
END;

-- Update Pharmacy Contact
DROP PROCEDURE IF EXISTS update_pharmacy_contact;
CREATE PROCEDURE update_pharmacy_contact (
    IN p_name VARCHAR(100),
    IN p_contact VARCHAR(15)
)
BEGIN
    UPDATE Pharmacy SET PhoneNo = p_contact WHERE Name = p_name;
END;

-- Delete Pharmacy
DROP PROCEDURE IF EXISTS delete_pharmacy;
CREATE PROCEDURE delete_pharmacy (
    IN p_name VARCHAR(100)
)
BEGIN
    DELETE FROM Pharmacy WHERE Name = p_name;
END;

-- ================================
-- Sells CRUD Procedures
-- ================================

-- Create Sells entry
DROP PROCEDURE IF EXISTS add_sells;
CREATE PROCEDURE add_sells (
    IN p_pharmacy VARCHAR(100),
    IN p_trade_name VARCHAR(100),
    IN p_company_name VARCHAR(100),
    IN p_price DECIMAL(10,2)
)
BEGIN
    INSERT INTO Sells (PharmacyName, TradeName, CompanyName, Price)
    VALUES (p_pharmacy, p_trade_name, p_company_name, p_price);
END;

-- Update Sells price
DROP PROCEDURE IF EXISTS update_sells;
CREATE PROCEDURE update_sells (
    IN p_pharmacy VARCHAR(100),
    IN p_trade_name VARCHAR(100),
    IN p_company_name VARCHAR(100),
    IN p_price DECIMAL(10,2)
)
BEGIN
    UPDATE Sells
    SET Price = p_price
    WHERE PharmacyName = p_pharmacy 
      AND TradeName = p_trade_name 
      AND CompanyName = p_company_name;
END;

-- Delete Sells entry
DROP PROCEDURE IF EXISTS delete_sells;
CREATE PROCEDURE delete_sells (
    IN p_pharmacy VARCHAR(100),
    IN p_trade_name VARCHAR(100),
    IN p_company_name VARCHAR(100)
)
BEGIN
    -- Check if this would violate the pharmacy minimum drugs trigger
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM Sells
    WHERE PharmacyName = p_pharmacy
      AND NOT (TradeName = p_trade_name AND CompanyName = p_company_name);

    IF v_count < 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A pharmacy must sell at least 10 drugs after deletion.';
    ELSE
        DELETE FROM Sells 
        WHERE PharmacyName = p_pharmacy 
          AND TradeName = p_trade_name 
          AND CompanyName = p_company_name;
    END IF;
END;

-- ================================
-- Prescription CRUD Procedures
-- ================================

-- -- Create Prescription
-- DROP PROCEDURE IF EXISTS add_prescription;
-- CREATE PROCEDURE add_prescription (
--     IN p_doctor CHAR(12),
--     IN p_patient CHAR(12),
--     IN p_date DATE
-- )
-- BEGIN
--     INSERT INTO Prescription (DoctorID, PatientID, Date)
--     VALUES (p_doctor, p_patient, p_date);
-- END;

-- Create Prescription with date checking
DROP PROCEDURE IF EXISTS add_prescription;
CREATE PROCEDURE add_prescription (
    IN p_doctor CHAR(12),
    IN p_patient CHAR(12),
    IN p_date DATE
)
BEGIN
    DECLARE v_existing_date DATE;
    
    -- Check if prescription exists for this doctor-patient pair
    SELECT Date INTO v_existing_date 
    FROM Prescription 
    WHERE DoctorID = p_doctor 
    AND PatientID = p_patient
    LIMIT 1;
    
    IF v_existing_date IS NOT NULL THEN
        -- If new date is more recent, delete old and insert new
        IF p_date > v_existing_date THEN
            -- Delete old prescription and its drugs
            DELETE FROM PrescriptionDrug 
            WHERE DoctorID = p_doctor 
            AND PatientID = p_patient;
            
            DELETE FROM Prescription 
            WHERE DoctorID = p_doctor 
            AND PatientID = p_patient;
            
            -- Insert new prescription
            INSERT INTO Prescription (DoctorID, PatientID, Date)
            VALUES (p_doctor, p_patient, p_date);
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot add prescription with earlier or same date';
        END IF;
    ELSE
        -- No existing prescription, simply insert new one
        INSERT INTO Prescription (DoctorID, PatientID, Date)
        VALUES (p_doctor, p_patient, p_date);
    END IF;
END;

-- Update Prescription Date (note: this changes the primary key)
DROP PROCEDURE IF EXISTS update_prescription_date;
CREATE PROCEDURE update_prescription_date (
    IN p_doctor CHAR(12),
    IN p_patient CHAR(12),
    IN p_old_date DATE,
    IN p_new_date DATE
)
BEGIN
    -- First update related PrescriptionDrug records
    UPDATE PrescriptionDrug
    SET Date = p_new_date
    WHERE DoctorID = p_doctor 
      AND PatientID = p_patient 
      AND Date = p_old_date;
      
    -- Then update the Prescription record
    UPDATE Prescription
    SET Date = p_new_date
    WHERE DoctorID = p_doctor 
      AND PatientID = p_patient 
      AND Date = p_old_date;
END;

-- Delete Prescription
DROP PROCEDURE IF EXISTS delete_prescription;
CREATE PROCEDURE delete_prescription (
    IN p_doctor CHAR(12),
    IN p_patient CHAR(12),
    IN p_date DATE
)
BEGIN
    -- First delete related PrescriptionDrug records
    DELETE FROM PrescriptionDrug
    WHERE DoctorID = p_doctor 
      AND PatientID = p_patient 
      AND Date = p_date;
    
    -- Then delete the Prescription record
    DELETE FROM Prescription
    WHERE DoctorID = p_doctor 
      AND PatientID = p_patient 
      AND Date = p_date;
END;

-- ================================
-- PrescriptionDrug CRUD Procedures
-- ================================

-- Create PrescriptionDrug
DROP PROCEDURE IF EXISTS add_prescription_drug;
CREATE PROCEDURE add_prescription_drug (
    IN p_doctor CHAR(12),
    IN p_patient CHAR(12),
    IN p_date DATE,
    IN p_trade_name VARCHAR(100),
    IN p_company_name VARCHAR(100),
    IN p_quantity INT
)
BEGIN
    -- First check if the prescription exists
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM Prescription
    WHERE DoctorID = p_doctor 
      AND PatientID = p_patient 
      AND Date = p_date;
    
    -- If not, create the prescription first
    IF v_count = 0 THEN
        INSERT INTO Prescription (DoctorID, PatientID, Date)
        VALUES (p_doctor, p_patient, p_date);
    END IF;
    
    -- Then add the prescription drug
    INSERT INTO PrescriptionDrug (DoctorID, PatientID, Date, TradeName, CompanyName, Quantity)
    VALUES (p_doctor, p_patient, p_date, p_trade_name, p_company_name, p_quantity);
END;

-- Update PrescriptionDrug Quantity
DROP PROCEDURE IF EXISTS update_prescription_drug;
CREATE PROCEDURE update_prescription_drug (
    IN p_doctor CHAR(12),
    IN p_patient CHAR(12),
    IN p_date DATE,
    IN p_trade_name VARCHAR(100),
    IN p_company_name VARCHAR(100),
    IN p_quantity INT
)
BEGIN
    UPDATE PrescriptionDrug
    SET Quantity = p_quantity
    WHERE DoctorID = p_doctor 
      AND PatientID = p_patient 
      AND Date = p_date
      AND TradeName = p_trade_name
      AND CompanyName = p_company_name;
END;

-- Delete PrescriptionDrug
DROP PROCEDURE IF EXISTS delete_prescription_drug;
CREATE PROCEDURE delete_prescription_drug (
    IN p_doctor CHAR(12),
    IN p_patient CHAR(12),
    IN p_date DATE,
    IN p_trade_name VARCHAR(100),
    IN p_company_name VARCHAR(100)
)
BEGIN
    DELETE FROM PrescriptionDrug
    WHERE DoctorID = p_doctor 
      AND PatientID = p_patient 
      AND Date = p_date
      AND TradeName = p_trade_name
      AND CompanyName = p_company_name;
END;

-- ================================
-- Contract CRUD Procedures
-- ================================

-- Create Contract
DROP PROCEDURE IF EXISTS add_contract;
CREATE PROCEDURE add_contract (
    IN p_pharma VARCHAR(100),
    IN p_pharmacy VARCHAR(100),
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_content TEXT,
    IN p_supervisor CHAR(12)
)
BEGIN
    INSERT INTO Contract (PharmaCompanyName, PharmacyName, StartDate, EndDate, Content, SupervisorAadharID)
    VALUES (p_pharma, p_pharmacy, p_start_date, p_end_date, p_content, p_supervisor);
END;

-- Update Contract
DROP PROCEDURE IF EXISTS update_contract;
CREATE PROCEDURE update_contract (
    IN p_pharma VARCHAR(100),
    IN p_pharmacy VARCHAR(100),
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_content TEXT,
    IN p_supervisor CHAR(12)
)
BEGIN
    UPDATE Contract
    SET EndDate = p_end_date,
        Content = p_content,
        SupervisorAadharID = p_supervisor
    WHERE PharmaCompanyName = p_pharma
      AND PharmacyName = p_pharmacy
      AND StartDate = p_start_date;
END;

-- Delete Contract
DROP PROCEDURE IF EXISTS delete_contract;
CREATE PROCEDURE delete_contract (
    IN p_pharma VARCHAR(100),
    IN p_pharmacy VARCHAR(100),
    IN p_start_date DATE
)
BEGIN
    DELETE FROM Contract
    WHERE PharmaCompanyName = p_pharma
      AND PharmacyName = p_pharmacy
      AND StartDate = p_start_date;
END;

-- ==========================
-- Utility Procedures
-- ==========================

-- Report generation procedures
DROP PROCEDURE IF EXISTS report_prescriptions_for_patient;
CREATE PROCEDURE report_prescriptions_for_patient (
    IN p_patient CHAR(12),
    IN p_start DATE,
    IN p_end DATE
)
BEGIN
    SELECT p.Date, d.Name AS DoctorName, pd.TradeName, pd.Quantity
    FROM Prescription p
    JOIN Doctor d ON p.DoctorID = d.AadharID
    JOIN PrescriptionDrug pd ON p.DoctorID = pd.DoctorID 
        AND p.PatientID = pd.PatientID 
        AND p.Date = pd.Date
    WHERE p.PatientID = p_patient 
        AND p.Date BETWEEN p_start AND p_end;
END;

-- Get drug details by company
DROP PROCEDURE IF EXISTS get_drugs_by_company;
CREATE PROCEDURE get_drugs_by_company (
    IN p_company VARCHAR(100)
)
BEGIN
    SELECT TradeName, Formula FROM Drug WHERE CompanyName = p_company;
END;

-- Get patients for doctor
DROP PROCEDURE IF EXISTS get_patients_for_doctor;
CREATE PROCEDURE get_patients_for_doctor (
    IN p_doctor CHAR(12)
)
BEGIN
    SELECT DISTINCT p.AadharID, p.Name, p.BirthDate
    FROM Patient p
    WHERE p.PrimaryPhysicianID = p_doctor;
END;

-- Get pharmacy stock position
DROP PROCEDURE IF EXISTS get_pharmacy_stock;
CREATE PROCEDURE get_pharmacy_stock (
    IN p_pharmacy_name VARCHAR(100)
)
BEGIN
    SELECT d.TradeName, d.Formula, d.CompanyName, s.Price
    FROM Sells s
    JOIN Drug d ON s.TradeName = d.TradeName 
        AND s.CompanyName = d.CompanyName
    WHERE s.PharmacyName = p_pharmacy_name
    ORDER BY d.CompanyName, d.TradeName;
END;

-- Get pharmacy-pharmaceutical company contact details
DROP PROCEDURE IF EXISTS get_pharmacy_pharma_contacts;
CREATE PROCEDURE get_pharmacy_pharma_contacts (
    IN p_pharmacy_name VARCHAR(100)
)
BEGIN
    SELECT 
        p.Name AS PharmacyName,
        p.PhoneNo AS PharmacyPhone,
        pc.Name AS CompanyName,
        pc.PhoneNo AS CompanyPhone,
        c.StartDate AS ContractStart,
        c.EndDate AS ContractEnd,
        d.Name AS SupervisorName
    FROM Pharmacy p
    JOIN Contract c ON p.Name = c.PharmacyName
    JOIN PharmaceuticalCompany pc ON c.PharmaCompanyName = pc.Name
    JOIN Doctor d ON c.SupervisorAadharID = d.AadharID
    WHERE p.Name = p_pharmacy_name;
END;

-- ==========================
-- Sample Data
-- ==========================

-- Core sample data for testing 

-- PATIENT (via stored procedure)



-- Insert Doctors
CALL add_doctor('D0001', 'Dr. A', 'Cardiology', 10);
CALL add_doctor('D0002', 'Dr. B', 'Neurology', 8);

-- Insert Patients
CALL add_patient('P0001', 'Alice', '123 Main St', '1990-05-10', 'D0001');
CALL add_patient('P0002', 'Bob', '456 Park Ave', '1985-07-15', 'D0002');

-- Insert Pharmaceutical Companies
CALL add_pharma_company('PharmaX', '9999999999');
CALL add_pharma_company('PharmaY', '8888888888');

-- Insert Drugs
CALL add_drug('Paracetamol', 'C8H9NO2', 'PharmaX');
CALL add_drug('Ibuprofen', 'C13H18O2', 'PharmaX');
CALL add_drug('Amoxicillin', 'C16H19N3O5S', 'PharmaY');
CALL add_drug('Drug1', 'F1', 'PharmaX');
CALL add_drug('Drug2', 'F2', 'PharmaX');
CALL add_drug('Drug3', 'F3', 'PharmaX');
CALL add_drug('Drug4', 'F4', 'PharmaX');
CALL add_drug('Drug5', 'F5', 'PharmaX');
CALL add_drug('Drug6', 'F6', 'PharmaX');
CALL add_drug('Drug7', 'F7', 'PharmaX');

-- Insert Pharmacy
CALL add_pharmacy('NovaCentral', 'Downtown', '7777777777');

-- Insert Sells data
CALL add_sells('NovaCentral', 'Paracetamol', 'PharmaX', 5.00);
CALL add_sells('NovaCentral', 'Ibuprofen', 'PharmaX', 8.00);
CALL add_sells('NovaCentral', 'Amoxicillin', 'PharmaY', 12.00);
CALL add_sells('NovaCentral', 'Drug1', 'PharmaX', 6.00);
CALL add_sells('NovaCentral', 'Drug2', 'PharmaX', 7.00);
CALL add_sells('NovaCentral', 'Drug3', 'PharmaX', 9.00);
CALL add_sells('NovaCentral', 'Drug4', 'PharmaX', 11.00);
CALL add_sells('NovaCentral', 'Drug5', 'PharmaX', 13.00);
CALL add_sells('NovaCentral', 'Drug6', 'PharmaX', 15.00);
CALL add_sells('NovaCentral', 'Drug7', 'PharmaX', 17.00);

-- Insert Prescriptions
CALL add_prescription('D0001', 'P0001', '2025-04-15');
CALL add_prescription_drug('D0001', 'P0001', '2025-04-15', 'Paracetamol', 'PharmaX', 2);
CALL add_prescription_drug('D0001', 'P0001', '2025-04-15', 'Ibuprofen', 'PharmaX', 1);

-- Insert Contract
CALL add_contract('PharmaX', 'NovaCentral', '2025-01-01', '2026-01-01', 'Standard supply contract.', 'D0001');


select * from doctor;
select * from patient;
select * from drug;
select * from pharmacy;
select * from pharmaceuticalcompany;
select * from sells;
select * from prescription;
select * from prescriptiondrug;

CALL add_patient('P0003', 'Bobby', '456 Park Ave', '1985-07-15', 'D0002');

CALL report_prescriptions_for_patient('P0001', '2023-01-01', '2025-05-16');

Call get_pharmacy_stock('NovaCentral');

CALL get_patients_for_doctor('D0002');

show databases;
use sample;
