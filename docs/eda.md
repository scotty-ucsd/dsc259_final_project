---
layout: page
step_number: "Step 2"
step_title: "Data Cleaning and EDA"
permalink: /eda/
---

## Background
As we embark on the data science life cycle, we must conduct a comprehensive inspection beyond the sneak peek that revealed major formatting issues in [Step 1: Introduction]({{ '/introduction/' | relative_url }}). During this phase, we polish the raw data into a usable format. Our cleaning process entails the following:
* **Duplicate Analysis:** Checking for and removing duplicate observations.
* **Null Element Inspection:** Analyzing the frequency and distribution of `NaN` or `Null` values.
* **Feature Definition:** Mapping out what each column represents to ensure contextual accuracy.
* **Data Type Standardization:** Converting columns to appropriate numeric or datetime types.

---

## Plan of Action
We will split this investigation into two distinct parts.

### Part A: Data Cleaning
1. **Address Formatting:** Trimming metadata rows and aligning headers.
2. **Define Features:** Clarifying the units and meanings of each column.
3. **Examine Dataset Size:** Quantifying rows, columns, and total elements.
4. **Inspect Nulls:** Identifying missingness across the dataset.

### Part B: Exploratory Data Analysis
1. **Standardize Units:** Converting raw values into comparable metrics.
2. **Standardize Features:** Normalizing column names for programmatic access.
3. **Univariate Analysis:** Analyzing the distribution of individual variables.
4. **Bivariate Analysis:** Exploring relationships between pairs of variables.
5. **Interesting Aggregates:** Utilizing pivot tables and group-bys to find hidden trends.

---

## Data Cleaning

### Address Formatting
A raw inspection of the dataset using `head` on `data/outage.csv` reveals a intricate structure at the top of the file that prevents standard CSV parsing:

```bash
head data/outage.csv

Major power outage events in the continental U.S.,,,,,
Time period: January 2000 - July 2016,,,,,,,,
Regions affected: Outages reported in this data file affected a single U.S. state...
,,,,,,,,
,,,,,,,,
variables,OBS,YEAR,MONTH,U.S._STATE,POSTAL.CODE...
Units,,,,,,,,numeric...
```

To "buff out the dents" of this irregular structure, we utilized targeted shell commands to bypass the metadata (rows 1-5) and the unit descriptions (row 7), resulting in a standardized file:

* **Extracting Headers:** 

```bash
head -6 data/outage.csv | tail -1 | cut -d ',' -f 2- > data/outage_clean.csv
```

* **Appending Data:** 

```bash
tail -n +8 data/outage.csv | cut -d ',' -f 2- >> data/outage_clean.csv
```

### Defined Features
The following table shows features in the dataset that have non-null units.

<div class="table-responsive">
    <table class="table table-striped">
        <thead>
            <tr>
                <th>Variable</th>
                <th>Units / Format</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><strong>ANOMALY.LEVEL</strong></td>
                <td>numeric</td>
            </tr>
            <tr>
                <td><strong>OUTAGE.START.DATE</strong></td>
                <td>Day of the week, Month Day, Year</td>
            </tr>
            <tr>
                <td><strong>OUTAGE.START.TIME</strong></td>
                <td>Hour:Minute:Second (AM / PM)</td>
            </tr>
            <tr>
                <td><strong>OUTAGE.RESTORATION.DATE</strong></td>
                <td>Day of the week, Month Day, Year</td>
            </tr>
            <tr>
                <td><strong>OUTAGE.RESTORATION.TIME</strong></td>
                <td>Hour:Minute:Second (AM / PM)</td>
            </tr>
            <tr>
                <td><strong>OUTAGE.DURATION</strong></td>
                <td>mins</td>
            </tr>
            <tr>
                <td><strong>DEMAND.LOSS.MW</strong></td>
                <td>Megawatt</td>
            </tr>
            <tr>
                <td><strong>RES.PRICE</strong></td>
                <td>cents / kilowatt-hour</td>
            </tr>
            <tr>
                <td><strong>COM.PRICE</strong></td>
                <td>cents / kilowatt-hour</td>
            </tr>
            <tr>
                <td><strong>IND.PRICE</strong></td>
                <td>cents / kilowatt-hour</td>
            </tr>
            <tr>
                <td><strong>TOTAL.PRICE</strong></td>
                <td>cents / kilowatt-hour</td>
            </tr>
            <tr>
                <td><strong>RES.SALES</strong></td>
                <td>Megawatt-hour</td>
            </tr>
            <tr>
                <td><strong>COM.SALES</strong></td>
                <td>Megawatt-hour</td>
            </tr>
            <tr>
                <td><strong>IND.SALES</strong></td>
                <td>Megawatt-hour</td>
            </tr>
            <tr>
                <td><strong>TOTAL.SALES</strong></td>
                <td>Megawatt-hour</td>
            </tr>
            <tr>
                <td><strong>RES.PERCEN</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>COM.PERCEN</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>IND.PERCEN</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>RES.CUST.PCT</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>COM.CUST.PCT</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>IND.CUST.PCT</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>PC.REALGSP.STATE</strong></td>
                <td>USD</td>
            </tr>
            <tr>
                <td><strong>PC.REALGSP.USA</strong></td>
                <td>USD</td>
            </tr>
            <tr>
                <td><strong>PC.REALGSP.REL</strong></td>
                <td>fraction</td>
            </tr>
            <tr>
                <td><strong>PC.REALGSP.CHANGE</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>UTIL.REALGSP</strong></td>
                <td>USD</td>
            </tr>
            <tr>
                <td><strong>TOTAL.REALGSP</strong></td>
                <td>USD</td>
            </tr>
            <tr>
                <td><strong>UTIL.CONTRI</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>PI.UTIL.OFUSA</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>POPPCT_URBAN</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>POPPCT_UC</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>POPDEN_URBAN</strong></td>
                <td>persons per square mile</td>
            </tr>
            <tr>
                <td><strong>POPDEN_UC</strong></td>
                <td>persons per square mile</td>
            </tr>
            <tr>
                <td><strong>POPDEN_RURAL</strong></td>
                <td>persons per square mile</td>
            </tr>
            <tr>
                <td><strong>AREAPCT_URBAN</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>AREAPCT_UC</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>PCT_LAND</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>PCT_WATER_TOT</strong></td>
                <td>%</td>
            </tr>
            <tr>
                <td><strong>PCT_WATER_INLAND</strong></td>
                <td>%</td>
            </tr>
        </tbody>
    </table>
</div>
### Dataset Size 
After standardizing the format, we examined the size of the data to gather the extent of missing information.
* **Columns:** 56
* **Rows:** 1534
* **Total elements:** 85904

### Null Inspection
The summary below captures the non-null counts and data types for our all columns containing any null values. Notable gaps will be addressed in [Step 3: Missingness]({{ '/missingness/' | relative_url }})

<div class="table-responsive">
    <table class="table table-hover">
        <thead>
            <tr>
                <th>#</th>
                <th>Column</th>
                <th>Non-Null Count</th>
                <th>Dtype</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>2</td>
                <td>MONTH</td>
                <td>1525 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>6</td>
                <td>CLIMATE.REGION</td>
                <td>1528 non-null</td>
                <td>object</td>
            </tr>
            <tr>
                <td>7</td>
                <td>ANOMALY.LEVEL</td>
                <td>1525 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>8</td>
                <td>CLIMATE.CATEGORY</td>
                <td>1525 non-null</td>
                <td>object</td>
            </tr>
            <tr>
                <td>9</td>
                <td>OUTAGE.START.DATE</td>
                <td>1525 non-null</td>
                <td>object</td>
            </tr>
            <tr>
                <td>10</td>
                <td>OUTAGE.START.TIME</td>
                <td>1525 non-null</td>
                <td>object</td>
            </tr>
            <tr>
                <td>11</td>
                <td>OUTAGE.RESTORATION.DATE</td>
                <td>1476 non-null</td>
                <td>object</td>
            </tr>
            <tr>
                <td>12</td>
                <td>OUTAGE.RESTORATION.TIME</td>
                <td>1476 non-null</td>
                <td>object</td>
            </tr>
            <tr>
                <td>14</td>
                <td>CAUSE.CATEGORY.DETAIL</td>
                <td>1063 non-null</td>
                <td>object</td>
            </tr>
            <tr>
                <td>15</td>
                <td>HURRICANE.NAMES</td>
                <td>72 non-null</td>
                <td>object</td>
            </tr>
            <tr>
                <td>16</td>
                <td>OUTAGE.DURATION</td>
                <td>1476 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>17</td>
                <td>DEMAND.LOSS.MW</td>
                <td>829 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>18</td>
                <td>CUSTOMERS.AFFECTED</td>
                <td>1091 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>19</td>
                <td>RES.PRICE</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>20</td>
                <td>COM.PRICE</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>21</td>
                <td>IND.PRICE</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>22</td>
                <td>TOTAL.PRICE</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>23</td>
                <td>RES.SALES</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>24</td>
                <td>COM.SALES</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>25</td>
                <td>IND.SALES</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>26</td>
                <td>TOTAL.SALES</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>27</td>
                <td>RES.PERCEN</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>28</td>
                <td>COM.PERCEN</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>29</td>
                <td>IND.PERCEN</td>
                <td>1512 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>49</td>
                <td>POPDEN_UC</td>
                <td>1524 non-null</td>
                <td>float64</td>
            </tr>
            <tr>
                <td>50</td>
                <td>POPDEN_RURAL</td>
                <td>1524 non-null</td>
                <td>float64</td>
            </tr>
        </tbody>
    </table>
</div>

---

## Exploratory Data Analysis
*Insert some comment here*

### Standardize and Select Features
#### 1. Datetime Standardization
The raw data split outage information into separate date and time strings (e.g., "Friday, July 1, 2011" and "5:00:00 PM"). We merged these and applied the explicit format string `%A, %B %d, %Y %I:%M:%S %p` to create unified `START.DATETIME` and `RESTORATION.DATETIME` features.

#### 2. Feature Refinement
* **Redundancy Removal:** We dropped the original `OUTAGE.START.DATE`, `OUTAGE.START.TIME`, `OUTAGE.RESTORATION.DATE`, and `OUTAGE.RESTORATION.TIME` columns.
* **Handling Incompletes:** We filtered out observations missing crucial temporal data, specifically dropping rows where `START.DATETIME`, `RESTORATION.DATETIME`, or `OUTAGE.DURATION` contained null values.

#### 3. Cleaned Data Head
Below is the result of `df_cleaned.head()` head of our the cleaned DataFrame:

<div class="table-responsive" style="overflow-x: auto; white-space: nowrap; padding-bottom: 15px;">
    <table class="table table-striped table-bordered" style="font-size: 0.8em;">
        <thead>
            <tr>
                <th>OBS</th><th>YEAR</th><th>MONTH</th><th>U.S._STATE</th><th>POSTAL.CODE</th><th>NERC.REGION</th><th>CLIMATE.REGION</th><th>ANOMALY.LEVEL</th><th>CLIMATE.CATEGORY</th><th>CAUSE.CATEGORY</th><th>...</th><th>POPDEN_URBAN</th><th>POPDEN_UC</th><th>POPDEN_RURAL</th><th>AREAPCT_URBAN</th><th>AREAPCT_UC</th><th>PCT_LAND</th><th>PCT_WATER_TOT</th><th>PCT_WATER_INLAND</th><th>START.DATETIME</th><th>RESTORATION.DATETIME</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>1</td><td>2011</td><td>7.0</td><td>Minnesota</td><td>MN</td><td>MRO</td><td>East North Central</td><td>-0.3</td><td>normal</td><td>severe weather</td><td>...</td><td>2279.0</td><td>1700.5</td><td>18.2</td><td>2.14</td><td>0.6</td><td>91.592666</td><td>8.407334</td><td>5.478743</td><td>2011-07-01 17:00:00</td><td>2011-07-03 20:00:00</td>
            </tr>
            <tr>
                <td>2</td><td>2014</td><td>5.0</td><td>Minnesota</td><td>MN</td><td>MRO</td><td>East North Central</td><td>-0.1</td><td>normal</td><td>intentional attack</td><td>...</td><td>2279.0</td><td>1700.5</td><td>18.2</td><td>2.14</td><td>0.6</td><td>91.592666</td><td>8.407334</td><td>5.478743</td><td>2014-05-11 18:38:00</td><td>2014-05-11 18:39:00</td>
            </tr>
            <tr>
                <td>3</td><td>2010</td><td>10.0</td><td>Minnesota</td><td>MN</td><td>MRO</td><td>East North Central</td><td>-1.5</td><td>cold</td><td>severe weather</td><td>...</td><td>2279.0</td><td>1700.5</td><td>18.2</td><td>2.14</td><td>0.6</td><td>91.592666</td><td>8.407334</td><td>5.478743</td><td>2010-10-26 20:00:00</td><td>2010-10-28 22:00:00</td>
            </tr>
            <tr>
                <td>4</td><td>2012</td><td>6.0</td><td>Minnesota</td><td>MN</td><td>MRO</td><td>East North Central</td><td>-0.1</td><td>normal</td><td>severe weather</td><td>...</td><td>2279.0</td><td>1700.5</td><td>18.2</td><td>2.14</td><td>0.6</td><td>91.592666</td><td>8.407334</td><td>5.478743</td><td>2012-06-19 04:30:00</td><td>2012-06-20 23:00:00</td>
            </tr>
            <tr>
                <td>5</td><td>2015</td><td>7.0</td><td>Minnesota</td><td>MN</td><td>MRO</td><td>East North Central</td><td>1.2</td><td>warm</td><td>severe weather</td><td>...</td><td>2279.0</td><td>1700.5</td><td>18.2</td><td>2.14</td><td>0.6</td><td>91.592666</td><td>8.407334</td><td>5.478743</td><td>2015-07-18 02:00:00</td><td>2015-07-19 07:00:00</td>
            </tr>
        </tbody>
    </table>
</div>

### Univariate Analysis
We examined the distribution of outage durations and their primary drivers. The **Outage Duration** histogram reveals a significant right-skew; while most outages are short-lived, the "long tail" represents extreme events that last thousands of minutes. Simultaneously, the **Cause Category** bar chart highlights "Severe Weather" and "Intentional Attack" as the most frequent triggers for outages in this dataset.

<div class="plotly-container" style="margin: 30px 0;">
    <iframe src="{{ site.baseurl }}/img/plots/outage_duration.html" width="100%" height="500px" frameborder="0"></iframe>
    <iframe src="{{ site.baseurl }}/img/plots/cause_category.html" width="100%" height="500px" frameborder="0"></iframe>
    <p class="text-muted text-center">
        <em>Figures 2 & 3: Most outages are caused by severe weather or intentional attacks...</em>
    </p>
</div>

### Bivariate Analysis
The effect season plays on outages, we looked at the relationship between the month an outage began and its duration.

<div class="plotly-container" style="margin: 30px 0;">
    <iframe src="{{ site.baseurl }}/img/plots/duration_month.html" width="100%" height="500px" frameborder="0"></iframe>
    <p class="text-muted text-center">
        <em>Figure 4: Outage durations across months. The log scale reveals extreme restoration times.</em>
    </p>
</div>

### Interesting Aggregates
The table below represents a pivot of the dataset, grouping by **Climate Region** and **Cause Category** to show the **Median Outage Duration**. This aggregation helps identify regional infrastructure vulnerabilities.

<div class="table-responsive" style="overflow-x: auto; display: block; width: 100%; padding-bottom: 15px;">
    <table class="table table-striped table-bordered" style="white-space: nowrap; font-size: 0.9em;">
        <thead>
            <tr>
                <th>CLIMATE.REGION</th>
                <th>equipment failure</th>
                <th>fuel supply emergency</th>
                <th>intentional attack</th>
                <th>islanding</th>
                <th>public appeal</th>
                <th>severe weather</th>
                <th>system operability disruption</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><strong>Central</strong></td>
                <td>149.0</td><td>7500.5</td><td>50.0</td><td>96.0</td><td>1410.0</td><td>1680.0</td><td>65.0</td>
            </tr>
            <tr>
                <td><strong>East North Central</strong></td>
                <td>761.0</td><td>13564.0</td><td>648.5</td><td>1.0</td><td>733.0</td><td>4005.0</td><td>2694.0</td>
            </tr>
            <tr>
                <td><strong>Northeast</strong></td>
                <td>159.0</td><td>12240.0</td><td>1.0</td><td>881.0</td><td>2760.0</td><td>3189.0</td><td>234.5</td>
            </tr>
            <tr>
                <td><strong>Northwest</strong></td>
                <td>702.0</td><td>1.0</td><td>74.0</td><td>21.0</td><td>898.0</td><td>3507.0</td><td>157.5</td>
            </tr>
            <tr>
                <td><strong>South</strong></td>
                <td>227.0</td><td>20160.0</td><td>100.0</td><td>493.5</td><td>430.0</td><td>2027.5</td><td>373.0</td>
            </tr>
            <tr>
                <td><strong>Southeast</strong></td>
                <td>308.5</td><td>NaN</td><td>108.0</td><td>NaN</td><td>4320.0</td><td>1355.0</td><td>110.0</td>
            </tr>
            <tr>
                <td><strong>Southwest</strong></td>
                <td>35.0</td><td>76.0</td><td>56.0</td><td>2.0</td><td>2275.0</td><td>2425.0</td><td>284.0</td>
            </tr>
            <tr>
                <td><strong>West</strong></td>
                <td>269.0</td><td>882.5</td><td>108.0</td><td>128.5</td><td>420.0</td><td>962.0</td><td>199.0</td>
            </tr>
            <tr>
                <td><strong>West North Central</strong></td>
                <td>61.0</td><td>NaN</td><td>0.5</td><td>56.0</td><td>439.5</td><td>83.0</td><td>NaN</td>
            </tr>
        </tbody>
    </table>
</div>

---

## Checkpoint Questions

#### 1. Data Cleaning
* **Report on Website:** Describe, in detail, the data cleaning steps you took and how they affected your analyses. The steps should be explained in reference to the data generating process. Show the head of your cleaned DataFrame (see Part 2: Report for instructions
*See Background and Brief Description sections above.*

#### 2. Univariate Analysis
* **Report on Website:** Embed at least one plotly plot you created in your notebook that displays the distribution of a single column (see Part 2: Report for instructions). Include a 1-2 sentence explanation about your plot, making sure to describe and interpret any trends present. (Your notebook will likely have more visualizations than your website, and that’s fine. Feel free to embed more than one univariate visualization in your website if you’d like, but make sure that each embedded plot is accompanied by a description.)

#### 3. Bivariate Analysis
* **Report on Website:** Embed at least one plotly plot that displays the relationship between two columns. Include a 1-2 sentence explanation about your plot, making sure to describe and interpret any trends present. (Your notebook will likely have more visualizations than your website, and that’s fine. Feel free to embed more than one bivariate visualization in your website if you’d like, but make sure that each embedded plot is accompanied by a description.)

#### 4. Interesting Aggregates
* **Report on Website:** Embed at least one grouped table or pivot table in your website and explain its significance. 


