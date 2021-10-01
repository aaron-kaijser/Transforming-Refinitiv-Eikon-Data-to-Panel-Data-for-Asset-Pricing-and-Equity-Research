#### Aaron Kaijser (2021)
#### This function helps to transform raw data output of Refinitiv Eikon's Excel add-in into panel data
#### https://github.com/aaron-kaijser/Transforming-Refinitiv-Eikon-Data-to-Panel-Data-for-Asset-Pricing-and-Equity-Research

rm(list=ls()) # clears environment
gc() # clears garbage in memory


# Libraries ---------------------------------------------------------------
library(data.table) # data wrangling
library(stringr) # to extract strings 
library(zoo) # for trimming leading NA values


# Importing data ----------------------------------------------------------
dt <- fread("https://raw.githubusercontent.com/aaron-kaijser/Transforming-Refinitiv-Eikon-Data-to-Panel-Data-for-Asset-Pricing-and-Equity-Research/main/UK_2000_2020.csv")


# Function
ds_transform <- function(data) {
  # Removing rows -----------------------------------------------------------
  data <- data[-c(1:4,6),] # drops rows we don't need
  names(data) <- as.character(data[1,]) # changes column names to values in row 1
  data <- data[-1,] # drops first row
  
  # Extracting variable names -----------------------------------------------
  rows <- names(data)[-1] # subsets first row and drops first column ("code" column)
  varnames <- unique(str_extract(string = rows, pattern = "(?<=\\().*(?=\\))"))
  varnames <- varnames[!is.na(varnames)] # removes NA value (caused by missing data in Datastream)
  
  # varnames will be used to transpose the dataset in the right way among others
  total_number_stocks <- (dim(data)[2] - 1) / length(varnames)
  message(paste0("Total number of unique stocks in this dataset is: ", total_number_stocks, ". If this is not correct, something went wrong."))
  message(paste0("Total number of variables per stock is: ", length(varnames), ". If this is not correct, something went wrong."))
  
  # Preparing dataframe -----------------------------------------------------
  # Generating a vector with the right column names
  names <- gsub("\\s*\\([^\\)]+\\)\\s*$", "", rows) # removes text between parentheses (i.e "GB00BMSKPJ95(RI)" to "GB00BMSKPJ95")
  
  # for loop that pastes variable names to stock names (i.e. "GB00BMSKPJ95" becomes "GB00BMSKPJ95_RI" - makes transposing easier)
  sequ <- seq(1, (length(names) + length(varnames)-1), by = length(varnames)) # creates a vector to iterate over
  empty_vec_list <- list() # empty list to store values
  for (i in 1:(length(sequ)-1)) {
    vec <- names[sequ[i]:(sequ[i+1]-1)] # subsets vector with names
    name <- unique(vec[vec != ""]) # removes any empty strings caused by errors in Datatream
    if (length(name) != 0) { # if name is empty (which implies that for this stock, no data was available for all variables) save as empty string
      vec[vec == ""] <- name 
    } 
    empty_vec_list[[i]] <- as.data.table(vec) # binds all values together
  }
  names <- rbindlist(empty_vec_list)[[1]] # saves all column names
  rm(empty_vec_list) # clean up
  
  # for loop that appends variable names to list of names we just created (makes transposing easier)
  empty_list <- list()
  for (i in 1:length(names)) {
    reps <- rep(1:length(varnames), length(names)) # vector that indicates which variable name to paste behind stock name
    empty_list[[i]] <- as.data.table(paste0(rep(names[i], 1), "_", varnames[reps[i]])) # pastes variable names after stock ID
  }
  names_vars <- rbindlist(empty_list)[[1]] # [[1]] turns this into a vector - does not reference anything
  rm(empty_list) # clean up
  
  # Replacing existing column names with the right column names
  colnames(data)[-1] <- names_vars
  
  # Transposing dataframe ---------------------------------------------------
  data <- melt(data,
       measure = patterns(varnames), # looks for patterns in column names that match the variable names in order to transpose properly
       variable.name = "Stock",
       value.name = varnames)
  
  # Creating vector which we will use to replace stock placeholders (1,2,3 etc by actual stock codes/names)
  unique_names <- rep(1, length(names) / length(varnames)) # fills vector equal to length we require (speeds up computation)
  for (i in 1:length(unique_names)) {
    vec <- names[sequ[i]:(sequ[i+1]-1)] # sequ is a vector used only to reference the elements we need in 'names'
    unique_names[i] <- unique(vec)
  }
  data$Stock <- unique_names[data$Stock] # replaces 1, 2, etc. by actual stock name or number (ISIN for example)
  
  # Removes stocks for which no values were available to begin with
  data <- data[Stock != ""]
  
  # Printing message that tells us how many stocks have been deleted
  message(paste0("Of the ", total_number_stocks, " unique stocks, ", sum(unique_names == ""), " have been removed because they have no values."))
  
  # Changing date column name
  setnames(data, old = c("Code"), new = c("Date"))
  
  # Changing character columns to numeric columns (will change $$ER strings to NA which will cause warnings, I supress those)
  suppressWarnings(data[, (varnames) := lapply(.SD, function(x) as.numeric(x)), .SDcols = varnames])
  
  # Removing leading NA values
  data <- data[data[, na.trim(data.table(RI, .I), "left"), by = Stock]$.I,]
  
  # Removing trailing NA values
  data <- data[data[, na.trim(data.table(RI, .I), "right"), by = Stock]$.I,]
  
  # Calculates returns (so we can remove trailing returns of 0 (Datastream doesn't end the time-series after delisting))
  data[, ret := round((RI - shift(RI, n=1)) / shift(RI, n=1), 6), by = Stock][, RI := NULL]
  
  # Removes first NA return row caused by calculating returns per security
  data <- data[data[, tail(data.table(ret, .I), (.N-1)), by = Stock]$.I,]
  
  # Removes trailing returns of 0 (will delete any returns after delisting)
  data <- data[, {
    r <- rle(ret)
    if (last(r$values) == 0 | is.na(last(r$values)))
      head(.SD, -last(r$lengths))
    else
      .SD
  }, Stock]
  
  # Printing how many other stocks have been removed
  message(paste0("Another ", total_number_stocks - sum(unique_names == "") - length(unique(data$Stock)), 
                 " stocks have been removed from the sample due to missing returns. The final number of unique stocks is: ",
                 length(unique(data$Stock))))
  
  return(data) # returns dataframe
}

transformed_df <- ds_transform(dt)


