# How to operate this repository

1. run the command `git clone https://github.com/Shreenivas2004/E-commerce-Sales-Customer-Experience-Analysis` in your terminal to clone the repo 
2. create a new db in your mysql named 'oilst'
3. run the import_table_to_sql.py file to import the csv files to the database 
4. run the sql files in the order Table apporpriation.sql -> master_table.sql -> 01.sql and 02.sql
5. Now you have the views and tables in your database


## What are the contents of the files

### import_table_to_sql.py

This file contains python code to import csv files into mysql database. There need to be an existing database named oilst for this to work 

After you run the file, it will ask for an input for password to the mysql server and will show progress for creation of tables in mysql servers

Please make sure to run it while keeping the folder structure of the orignal project intact

### Table appropriation.sql

This file contains sql queiers to set the primary and foreign keys for the tables as that is not being done in the python code and without it we cannot perform the exercise that needs to be done

### master_table.sql

This file contains sql queires to create the master table which will be used to create views and Dax Queries later on when we get to Power BI

### 01.sql

This file contains sql queires to create the views for analysis

### 02.sql

This file contains sql queires to create the views for analysis

