import pandas as pd
import mysql.connector
import os
from sqlalchemy import create_engine
from urllib.parse import quote_plus

password = input("Enter password: ")
engine = create_engine(f"mysql+mysqlconnector://root:{password}@localhost:3306/oilst",pool_pre_ping=True, pool_recycle=3600)

mydb = mysql.connector.connect(
	host = "localhost",
	user = "root",
	password = "Manu@2004",
	database = "oilst"
	)
folder = r"C:\Users\shree\Documents\oilst analysis\raw data files"

file_names  = {f: "_".join(f[:-4].split("_")[1:-1]) for f in os.listdir(folder)}
dfs = []
i=0
for file,table in file_names.items():
	dfs.append(table)
	table = pd.read_csv(os.path.join(folder,file))
	table.to_sql(dfs[i],engine,if_exists="replace", index=False)
	print(f"{dfs[i]} added to sql")
	i+=1





