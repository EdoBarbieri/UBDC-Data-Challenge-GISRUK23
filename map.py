#import packages
import pandas as pd
import geopandas as gpd
import numpy as np

#%% import datasets
shapefile = gpd.read_file([1])
SIMDranks = pd.read_csv([2])

#%% select columns of interests and prepare for join
SIMDranks = SIMDranks[["Data_Zone", 
                       "Intermediate_Zone", 
                       "Council_area", 
                       "SIMD2020v2_Rank"]]

shapefile = shapefile.rename(columns={'DataZone': 'Data_Zone'})

#%% Left Outer Join

df = pd.merge(shapefile, SIMDranks, how="left", on="Data_Zone")

#%% What do we need for our maps?

#Only Rows in Glasgow City council

df = df[(df.Council_area == "Glasgow City")]

#Boolean for food deserts

Food_Deserts = np.array(["Dalmarnock",
                 "Central Easterhouse",
                 "Wyndford",
                 "Drumchapel North",
                 "Crookston South",
                 "Drumchapel South",
                 "Craigend and Ruchazie",
                 "Glenwood South"])

df["isFoood_Desert"] = df["Intermediate_Zone"].isin(Food_Deserts)
