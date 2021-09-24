# Transforming-Refinitiv-Eikon-Data-to-Panel-Data-for-Asset-Pricing-and-Equity-Research
This repository provides guidance in transforming raw data output from Refinitiv Eikon's horrendous Excel add-in to panel data for asset pricing or equity research with R.

## 1. Acquiring the right data output format
![Datastream_1](https://user-images.githubusercontent.com/52838190/134586200-c414aca1-e76b-41cd-9d0a-78125a019847.png)
1. Indicate which equities you would like to retrieve data for. I created a custom list (L#UKTEST) which contains 4,601 dead and active U.K. equities that were or are listed on the 
London Stock Exchange (see Ince and Porter (2006) on how to apply static and dynamic filters in order to obtain all equities for a particular country). 
1. Select the variables that you would like. In this case, I selected RI (Return Index - used to calculate dividend adjusted returns), WC01001 (Worldscope annual sales item) and NOSH (total number of shares outstanding). **Note**: because my list contains 4,601 unique equities, I cannot select more than 3 variables. Excel has a column limit of 16,384 columns which means that including an additional variable would exceed this limit. Transposing won't help either. I'll come back to this below.
1. Select the date range. It is recommended to use monthly values as well as end of the month dates here.
1. Untick this box, the script takes care of this.
1. Untick this box as well.

Save the output as a comma separated values **(.csv)** file. Do not save as .xls(x) as reading in .csv files is much faster and the often used read_excel() function from R's readxl package will likely fail to read the dates. 

**Make sure that you always select the RI variable as this determines the starting date as well as the ending date (in case of a delisted or dead security) of the time series of each security.**

## 2. Running the script
The script was created using R version 4.0.5 and only requires the data.table, stringr and zoo packages to be installed in order to work. To install these packages, run the following line in your R console:
```
 install.packages(c("data.table", "stringr", "zoo"))
```
After making sure that these packages have been loaded into your R session, simply import your raw .csv Datastream output using data.table's ```fread()``` function and run the function. 

Using the example code that I provided here (U.K. equities between January 2000 and December 2020), the function will tell the following:
```
> dt <- ds_transform(dt)
Total number of unique stocks in this dataset is: 4601. If this is not correct, something went wrong.
Total number of variables per stock is: 3. If this is not correct, something went wrong.
Of the 4601 unique stocks, 25 have been removed because they have no values.
Another 959 stocks have been removed from the sample due to missing returns. The final number of unique stocks is: 3617
```
- The function detects the amount of unique stocks based on the dimensions of your raw data input. If this number is incorrect, check whether your Datastream time series request did not exceed Excel's maximum column width of 16,384 columns.
- It will detect the number of unique variables that you requested based on the values that Datastream outputs behind the stock names or numbers (i.e. AAPL(RI) or AAPL(NOSH)).
- It will detect the number of stocks that are removed because they contain no values at all (all requested variables for this stock throw an error ($$ER)). 
- After removing leading and trailing NA values and trailing 0 returns after calculating the returns, it will tell you how many stocks have been removed because they simply do not have any returns in the time period you requested. In my case, 959 stocks because they were most likely listed on the LSE prior to 2000. 

## 3. Examples
### Example 1
#### Raw .csv input
The following .csv file can be found in this repository and is the dataset that I used earlier and looks as follows:
![image](https://user-images.githubusercontent.com/52838190/134646063-47b0ffd0-f527-4aec-994b-57625ac924de.png)

#### Function output
The function transform the initial 258 x 13,804 matrix into a panel data with a total of approximately 370,000 observations for 3,617 stocks. 
```
> head(dt, 20)
           Stock       Date WC01001   NOSH       ret
 1: GB00BMSKPJ95  31-7-2014  983500 554000 -0.016129
 2: GB00BMSKPJ95  29-8-2014  983500 554000  0.147541
 3: GB00BMSKPJ95  30-9-2014  983500 554000  0.151786
 4: GB00BMSKPJ95 31-10-2014  983500 554000  0.037984
 5: GB00BMSKPJ95 28-11-2014  983500 554000  0.078417
 6: GB00BMSKPJ95 31-12-2014  983500 554000 -0.023546
 7: GB00BMSKPJ95  30-1-2015  983500 554000  0.014894
 8: GB00BMSKPJ95  27-2-2015  973000 554000  0.055206
 9: GB00BMSKPJ95  31-3-2015  973000 605937  0.076291
10: GB00BMSKPJ95  30-4-2015  973000 605937  0.035688
11: GB00BMSKPJ95  29-5-2015  973000 605937 -0.020081
12: GB00BMSKPJ95  30-6-2015  973000 605937 -0.093670
13: GB00BMSKPJ95  31-7-2015  973000 605937 -0.015386
14: GB00BMSKPJ95  31-8-2015  973000 605937 -0.088729
15: GB00BMSKPJ95  30-9-2015  973000 608070 -0.147916
16: GB00BMSKPJ95 30-10-2015  973000 608070 -0.010500
17: GB00BMSKPJ95 30-11-2015  973000 608070 -0.024936
18: GB00BMSKPJ95 31-12-2015  973000 608070  0.162964
19: GB00BMSKPJ95  29-1-2016  973000 608070 -0.062383
20: GB00BMSKPJ95  29-2-2016  940000 608070 -0.033683
```

### Example 2
I downloaded a small dataset containing 6 different stocks with 9 different variables. After running the output I obtain the following:
```
> dt <- ds_transform(data)
Total number of unique stocks in this dataset is: 6. If this is not correct, something went wrong.
Total number of variables per stock is: 9. If this is not correct, something went wrong.
Of the 6 unique stocks, 0 have been removed because they have no values.
Another 0 stocks have been removed from the sample due to missing returns. The final number of unique stocks is: 6
```
```
> head(dt, 20)
    Stock       Date WC01001   NOSH    UP      MV WC01051 WC02999 WC02101 WC02255       ret
 1:   AZN  30-6-1993 4440000 944688 625.0 5904.30 1713000 4962000  776000      NA -0.011100
 2:   AZN  30-7-1993 4440000 944688 634.5 5994.04 1713000 4962000  776000      NA  0.015269
 3:   AZN  31-8-1993 4440000 944688 714.0 6745.07 1713000 4962000  776000      NA  0.125199
 4:   AZN  30-9-1993 4440000 944688 719.0 6792.30 1713000 4962000  776000      NA  0.025493
 5:   AZN 29-10-1993 4440000 944688 773.0 7302.43 1713000 4962000  776000      NA  0.075097
 6:   AZN 30-11-1993 4440000 944688 764.0 7217.41 1713000 4962000  776000      NA -0.011642
 7:   AZN 31-12-1993 4440000 944688 840.5 7940.10 1713000 4962000  776000      NA  0.100162
 8:   AZN  31-1-1994 4480000 944688 806.0 7614.18 1628000 4681000  776000      NA -0.041054
 9:   AZN  28-2-1994 4480000 944688 769.0 7264.64 1628000 4681000  776000      NA -0.045892
10:   AZN  31-3-1994 4480000 944688 725.0 6848.98 1628000 4681000  776000      NA -0.030102
11:   AZN  29-4-1994 4480000 944688 689.0 6508.89 1628000 4681000  776000      NA -0.049675
12:   AZN  31-5-1994 4480000 944688 680.0 6423.88 1628000 4681000  776000      NA -0.013046
13:   AZN  30-6-1994 4480000 944688 727.0 6867.88 1628000 4681000  776000      NA  0.069109
14:   AZN  29-7-1994 4480000 944688 743.5 7023.75 1628000 4681000  776000      NA  0.022654
15:   AZN  31-8-1994 4480000 944688 839.0 7925.93 1628000 4681000  776000      NA  0.128449
16:   AZN  30-9-1994 4480000 946000 807.5 7638.95 1628000 4681000  776000      NA -0.021788
17:   AZN 31-10-1994 4480000 946000 861.0 8145.05 1628000 4681000  776000      NA  0.066231
18:   AZN 30-11-1994 4480000 946000 845.0 7993.70 1628000 4681000  776000      NA -0.018545
19:   AZN 30-12-1994 4480000 946000 879.0 8315.34 1628000 4681000  776000      NA  0.040180
20:   AZN  31-1-1995 4898000 945976 875.0 8277.29 1908000 5050000  851000      NA -0.004525
```

## 4. Extra notes
### 1. Lagging the data in order to prevent data loss
If you want to avoid losing data when you want to construct factors, take into account the following. Different databases output data in different manners. For example, Compustat and Datastream record annual information such as annual sales (WC01001 in Datastream) in different ways. Compustat Global gives you the reporting date and the value, whereas Datastream will "backfill" the reported data when you download your raw data using a monthly frequency. 

Let's take the annual sales of AstraZeneca in 1992 (ISIN: GB0009895292) as an example. Compustat Global only states that the reporting date was 31/12/1992 and total sales were 3,979 mln GBP. Datastream, in constrast, simply spreads this number over the months between January 1992 and December 1992 (when you download monthly data). However, the returns of AstraZeneca are only available from June 1993 onwards in Datastream. Because I use the first available monthly return value as the beginning of the time-series for each security, these values (3,979 mln) are removed from the data. The issue here is that annual accounting information is often assumed to become known to the market after 6 months. Hence, in this case (knowing that the reporting date was at 31/12/1992) what one should do when working with monthly data is to lag all the annual sales by 6 months (by each stock) and in Datastream's case by an additional 12 months - such that the annual sales of AstraZeneca (3,979 mln GBP) reported on 31/12/1992 are known to the market in July 1993 and the subsequent months.

The problem is that when you do this **after** running this script, you will end up with multiple leading NA rows for each security in your dataset, despite the fact that you could have had values there. Although this isn't necessarily problematic, I can imagine that in some cases you would want to avoid this. My advice is to adjust the script: after the line 
```# Changing character columns to numeric columns (will change $$ER strings to NA which will cause warnings, I supress those)``` 
you should lag your variables appropriately (i.e. annual variables should are assumed to become known after 6 months, quarterly variables are assumed to become known after 4 months etc.). Because lagging depends on the nature of your variables I cannot implement this in this function and you will have to look at this yourself. 

For example, suppose I want to lag the annual sales (WC01001) in the example data I provided. I will add the following line: ```data[, WC01001 := shift(WC01001, n = 18), by = Stock]``` to the function, such that:

```
# Changing character columns to numeric columns (will change $$ER strings to NA which will cause warnings, I supress those)
suppressWarnings(data[, (varnames) := lapply(.SD, function(x) as.numeric(x)), .SDcols = varnames])
  
# Lagging the variables
data[, WC01001 := shift(WC01001, n = 18), by = Stock]
  
# Removing leading NA values
data <- data[data[, na.trim(data.table(RI, .I), "left"), by = Stock]$.I,]
```

Then simply run the script again. If you want to lag multiple variables at once, do the following:
```
# Lagging the variables
cols <- c("WC01001", "NOSH") # creates a vector containing the names of annual accounting variables
data[, (cols) := shift(.SD, n = 18), by = Stock, .SDcols = cols] # lags all the annual variables by 18 months 
```

### 2. Large datasets
As I mentioned earlier, Excel has a column limit aswell as a row limit. Suppose I want to download more than the 3 variables I have here for my 4,601 U.K. stocks and I want 4 variables instead. The problem here is that 4,601 x 4 = 18,404 and therefore exceeds the column limit. Transposing doesn't help, because 4,601 x 252 exceeds the row limit as well. The only way to overcome this problem is by simply requesting 3 variables at a time, and doing this multiple times. You then load in the different (raw) datasets and run the function multiple times. In the end, you merge the different dataframes you have on date and stock name or ID. 
