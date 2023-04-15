#Where should we put New supermarket to efficiently tackle Food Deserts in Glasgow?


#Import three datasets
#SIMD is the one containing the SIMD ranks [1]
#Supermarket is the one containing the distances (in minutes) from the closest supermarket using public transport[2]
#TTM is the Time Travelling Matrix for Public Transports [3]



#Install "dplyr" if needed.
#install.packages("dplyr")
library(dplyr)

#Change names of variables to make em more understandable and convenient for this specific analysis
colnames(SIMD)[1] <- "Data_Zones"
colnames(Supermarket)[1] <- "Data_Zones"
colnames(Supermarket)[19] <- "Nearest_Supermarket"

SIMD <- left_join(SIMD,
          Supermarket[,c(1,19)],
          by = "Data_Zones")


#Create a Boolean to subset data within Glasgow City Council
Glasgow <- SIMD$Council_area=="Glasgow City"
SIMD <- SIMD[Glasgow,]

#Which are the 20% more deprived data zones in Glasgow?
SIMD$SIMD2020v2_Rank <- as.numeric(SIMD$SIMD2020v2_Rank)
Theta <- sort(SIMD$SIMD2020v2_Rank, decreasing = TRUE)[596] #150 is almost 20% of 746
MostDeprived <- SIMD$SIMD2020v2_Rank<=Theta
SIMDMostDeprived <- SIMD[MostDeprived,]


#Creating a variable, TRUE if the Data Zone is within one of Kellog's Food Deserts
FoodDeserts <- c("Dalmarnock",
                 "Central Easterhouse",
                 "Wyndford",
                 "Drumchapel North",
                 "Crookston South",
                 "Drumchapel South",
                 "Craigend and Ruchazie",
                 "Glenwood South")
FoodDesertsBoolean <- SIMD$Intermediate_Zone %in% FoodDeserts
SIMDFoodDeserts <- SIMD[FoodDesertsBoolean,]


DataFrame <- data.frame("Data_Zones" = SIMD$Data_Zones,
                        "Intermediate_Zone" = SIMD$Intermediate_Zone,
                        "Total_Population" = SIMD$Total_population,
                        "SIMD_Rank" = SIMD$SIMD2020v2_Rank,
                        "Nearest_Supermarket" = SIMD$Nearest_Supermarket,
                        "Most_Deprived" = MostDeprived,
                        "Food_Deserts" = FoodDesertsBoolean)


#Within the 37 Data Zones classified as food deserts, where's the optimal place to put a new supermarket?
## We want to decrease the time spent on public transport for the most Health Deprived Areas
## Where should we put the supermarkets? Within the Food Deserts areas, since Public Transport Accessibility Data does not take into accout which areas are not only far from supermarkets but also food insecure.
## Where should we open it?

FromBoolean <- TTM$fromId %in% SIMDMostDeprived$Data_Zones
ToBoolean <- TTM$toId %in% SIMDFoodDeserts$Data_Zones
TTMOfInterest <- FromBoolean & ToBoolean
TTMOfInterestDF <-TTM[TTMOfInterest,]

#How much is every food desert gonna decrease?
ZonesFoodDeserts <- SIMDFoodDeserts$Data_Zones
ZonesDeprivedAreas <- SIMDMostDeprived$Data_Zones

#Creating a variable to store measure to evaluate the intervention
SIMDFoodDeserts$Reduced <- 0


for(i in ZonesFoodDeserts){
 DataFrameTemp <- TTMOfInterestDF[TTMOfInterestDF$toId==i,] #Every Food Desert
 for(j in ZonesDeprivedAreas){
          # Compare the distance to food desert to the distance to Data Zone
             # We need the index to extract
   indexTTM <- DataFrameTemp$fromId==j
   TimeToFoodDesert <- DataFrameTemp$travel_time_p050[indexTTM]
   
   indexSIMD <- SIMDMostDeprived$Data_Zones==j
   TimeToSupermarket <- SIMDMostDeprived$Nearest_Supermarket[indexSIMD]
   
   # weight for number of people potentially afflicted by the change 
   Weight <- SIMDMostDeprived$Total_population[indexSIMD]
   
   quantity <- (TimeToFoodDesert - TimeToSupermarket) * Weight
   
   # if this quantity is positive, it means that it has improved the public transport time to go to a supermarket
   
   if(quantity>0){
     indexSIMDto <- SIMDFoodDeserts$Data_Zones==i
     SIMDFoodDeserts$Reduced[indexSIMDto] <- quantity
   }
 }
}
