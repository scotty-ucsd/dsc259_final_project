---
layout: report
title: Project Analysis Report
permalink: /report/
---

<h1 style="text-align:center;">Power Down: Understanding U.S. Grid Outages</h1>

<p style="text-align:center; font-size: 1.1em;">
Randall "Scotty" Rogers, Jillian O'Neel, Hans Hanson
</p>

<br>




<h2 id="introduction" style="scroll-margin-top: 60px;">Introduction</h2>

The dataset on **Major Power Outage Risks in the U.S.**, assembled by Purdue University's LASCI group, chronicles 1,534 severe grid failures that occurred across the continental United States between January 2000 and July 2016. Each entry conveys far more than a date: it records climate indicators, geographic and economic context at the state level, and demographic characteristics that together paint a rich portrait of the conditions surrounding each disruption.

Maintaining grid stability is critical to everything from national security to day‑to‑day life. Because the U.S. grid is a mosaic of interlocking regional networks, the factors that influence outages can change dramatically from one locale to the next. By integrating technical outage logs with socioeconomic data such as state GDP and urbanization, we aim to move beyond simple event summaries toward tools that can anticipate how severe an outage will be and enable more informed resource allocation.

---

<h3 id="question-identification" style="scroll-margin-top: 60px;">Question Identification</h3>

At the heart of this study lies a practical question:

> **Can we forecast the number of customers affected by an outage (`CUSTOMERS.AFFECTED`) using only information available when the outage begins?**

This metric is our proxy for public impact. Large outages ripple through communities, straining emergency services and infrastructure. An early, reasonably accurate estimate of customer loss could help utilities and first responders position crews and supplies before the scale is fully known.

---

<h3 id="dataset_overview" style="scroll-margin-top: 60px;">Dataset Overview</h3>

<div style="margin-left: 15px;">
<br>
<b>Number of rows</b> (after cleaning and with target value, i.e. CUSTOMERS.AFFECTED):   1,045
<br>
<br><b>Relevant Columns</b> (only information available at outage onset; see framing prediction problem below)
<br>
<br>
<table>
  <thead>
    <tr>
      <th>Column</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>U.S._STATE</td>
      <td>State in which power outage occurred</td>
    </tr>
    <tr>
      <td>NERC.REGION</td>
      <td>North American Electric Reliability Corporation (NERC) region in which power outage occurred</td>
    </tr>
    <tr>
      <td style="padding-right:30px;">CLIMATE.CATEGORY</td>
      <td>9 climate regions specified by the National Centers for Environmental Information</td>
    </tr>
    <tr>
      <td>CAUSE.CATEGORY</td>
      <td>Categories for events causing the power outages</td>
    </tr>
    <tr>
      <td>ANOMALY.LEVEL</td>
      <td>Pre‑published climate anomaly index, referring to El Niño/La Niña</td>
    </tr>
    <tr>
      <td>POPULATION</td>
      <td>Population of the U.S. state</td>
    </tr>
    <tr>
      <td>POPPCT_URBAN</td>
      <td>Percentage of the U.S. state population living in an urban area</td>
    </tr>
    <tr>
      <td>is_hurricane</td>
      <td>Boolean indicating whether causal event is a hurricane or not; detectable from weather forecasts</td>
    </tr>
  </tbody>
</table>

</div>

<h3 id="roadmap" style="scroll-margin-top: 60px;">Roadmap</h3>

We approach the question through a sequence of analytical stages:

1. **Data cleaning and exploratory analysis** to understand the raw material and surface key patterns.
2. **Missingness investigation** for columns such as `DEMAND.LOSS.MW` that are often blank.
3. **Hypothesis testing** to verify whether state identity matters beyond reliability region.
4. **Model development**, starting with a Ridge regression baseline and progressing to a Histogram‑based Gradient Boosting final model.
5. **Fairness assessment** to check for performance imbalances across states of different population sizes.

Each section builds on the last, turning insights from exploration into modeling choices and evaluation criteria.

<h2 id="data-cleaning-and-EDA" style="scroll-margin-top: 60px;">Data Cleaning and Exploratory Analysis</h2>


<h3 id="data-cleaning" style="scroll-margin-top: 60px;">Data Cleaning</h3>

The source file was an Excel workbook with metadata rows and redundant columns that had to be stripped. After converting to CSV and loading into a DataFrame, we removed eight duplicates for a working set of 1,526 unique events. The dataset’s 56 columns were sorted into seven thematic groups—identifiers, temporal data, spatial and climate attributes, outage impact and cause, electricity economics, state economics, and demographics/land use—so that we could tackle each group consistently.

Key transformation steps included:

1. Dropping the redundant `OBS` index column.
2. Merging start and restoration date/time into single datetime fields and discarding the originals.
3. Removing rows missing either timestamp to ensure reliable duration calculations.
4. Imputing six missing `CLIMATE.REGION` entries with state‑based labels.
5. Filling 471 missing `CAUSE.CATEGORY.DETAIL` entries by appending "unknown" to the parent category.
6. Creating a binary `is_hurricane` flag from the presence of `HURRICANE.NAMES` and dropping the original column.
7. Dropping rows with missing electricity economics data and removing `TOTAL.PRICE` as it is derivable.
8. Setting population density nulls for the District of Columbia to zero rather than discarding the row.

\
Head of cleaned dataframe (select columns, discussed or used for prediction below):

<table>
  <thead>
    <tr style="text-align: left;">
      <th style="padding-right:10px;">index</th>
      <th style="padding-right:15px;">U.S._STATE</th>
      <th style="padding-right:15px;">NERC.REGION</th>
      <th style="padding-right:15px;">ANOMALY.LEVEL</th>
      <th style="padding-right:15px;">CLIMATE.CATEGORY</th>
      <th style="padding-right:15px;">CAUSE.CATEGORY</th>
      <th style="padding-right:15px;">CAUSE.CATEGORY.DETAIL</th>
      <th style="padding-right:15px;">HURRICANE.NAMES</th>
      <th style="padding-right:15px;">DEMAND.LOSS.MW</th>
      <th style="padding-right:15px;">CUSTOMERS.AFFECTED</th>
      <th style="padding-right:15px;">POPULATION</th>
      <th style="padding-right:15px;">POPPCT_URBAN</th>
      <th style="padding-right:15px;">outage_start_dt</th>
      <th style="padding-right:15px;">outage_restoration_dt</th>
      <th style="padding-right:15px;">is_hurricane</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>Minnesota</td>
      <td>MRO</td>
      <td>-0.3</td>
      <td>normal</td>
      <td>severe weather</td>
      <td>severe weather unknown</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>70000.0</td>
      <td>5348119</td>
      <td>73.27</td>
      <td>2011-07-01 17:00:00</td>
      <td>2011-07-03 20:00:00</td>
      <td>False</td>
    </tr>
    <tr>
      <th>1</th>
      <td>Minnesota</td>
      <td>MRO</td>
      <td>-0.1</td>
      <td>normal</td>
      <td>intentional attack</td>
      <td>vandalism</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>5457125</td>
      <td>73.27</td>
      <td>2014-05-11 18:38:00</td>
      <td>2014-05-11 18:39:00</td>
      <td>False</td>
    </tr>
    <tr>
      <th>2</th>
      <td>Minnesota</td>
      <td>MRO</td>
      <td>-1.5</td>
      <td>cold</td>
      <td>severe weather</td>
      <td>heavy wind</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>70000.0</td>
      <td>5310903</td>
      <td>73.27</td>
      <td>2010-10-26 20:00:00</td>
      <td>2010-10-28 22:00:00</td>
      <td>False</td>
    </tr>
    <tr>
      <th>3</th>
      <td>Minnesota</td>
      <td>MRO</td>
      <td>-0.1</td>
      <td>normal</td>
      <td>severe weather</td>
      <td>thunderstorm</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>68200.0</td>
      <td>5380443</td>
      <td>73.27</td>
      <td>2012-06-19 04:30:00</td>
      <td>2012-06-20 23:00:00</td>
      <td>False</td>
    </tr>
    <tr>
      <th>4</th>
      <td>Minnesota</td>
      <td>MRO</td>
      <td>1.2</td>
      <td>warm</td>
      <td>severe weather</td>
      <td>severe weather unknown</td>
      <td>NaN</td>
      <td>250.0</td>
      <td>250000.0</td>
      <td>5489594</td>
      <td>73.27</td>
      <td>2015-07-18 02:00:00</td>
      <td>2015-07-19 07:00:00</td>
      <td>False</td>
    </tr>
  </tbody>
</table>



\
\
After cleaning, the DataFrame contains 1,456 observations. The columns most affected by remaining gaps are `DEMAND.LOSS.MW` (about 46% missing) and `CUSTOMERS.AFFECTED` (about 29%), topics we revisit in the next section.

---



<h3 id="univariate-analysis" style="scroll-margin-top: 60px;">Univariate Analysis</h3>


The distribution of outages by NERC reliability region reveals how physical grid structure, not political boundaries, governs outage frequency.

<iframe src="{{ site.baseurl }}/img/plots/univariate_plt3.html" width="100%" height="450" frameborder="0"></iframe>

Regions differ markedly, often reflecting population concentrations and exposure to severe weather. When we recast the counts by climate region and overlay a state‑level choropleth, a few states stand out as major contributors to their environmental zones—California in the West, Texas in the South, and so on.

<iframe src="{{ site.baseurl }}/img/plots/univariate_plt4.html" width="100%" height="450" frameborder="0"></iframe>

These two visualizations set the stage for more nuanced, feature‑level questions: Do outage durations shift by climate? Does month of year matter?

---

<h3 id="bivariate-analysis" style="scroll-margin-top: 60px;">Bivariate Analysis</h3>

A log‑scale box plot of outage duration by climate zone shows that median restoration times are fairly consistent across environments, but extremes—multi‑day outages—are more common in the Northeast and South.

<iframe src="{{ site.baseurl }}/img/plots/bivariate_plt5.html" width="100%" height="450" frameborder="0"></iframe>

Seasonal analysis using month‑grouped box plots indicates that typical durations barely budge over the calendar, even though the frequency and magnitude of outliers fluctuate with the seasons. In other words, while catastrophic storms can drive long outages at particular times of year, the everyday outage remains surprisingly steady.

<iframe src="{{ site.baseurl }}/img/plots/bivariate_plt6.html" width="100%" height="450" frameborder="0"></iframe>

This steady background suggests that predicting `CUSTOMERS.AFFECTED` will require factors beyond simple climactic timing.

<h3 id="interesting-aggregates" style="scroll-margin-top: 60px;">Interesting Aggregates</h3>


Below, we aggregate the data into a pivot table comparing outage duration across cause categories and climate regions. This helps identify whether certain types of disruptions are associated with longer recovery times in particular environmental contexts.

<table>
  <thead>
    <tr style="text-align: left;">
      <th style="padding-right:50px;">CAUSE.CATEGORY</th>
      <th style="padding-right:0px;">equipment failure</th>
      <th style="padding-right:0px;">fuel supply emergency</th>
      <th style="padding-right:0px;">intentional attack</th>
      <th style="padding-right:40px;">islanding</th>
      <th style="padding-right:0px;">public appeal</th>
      <th style="padding-right:0px;">severe weather</th>
      <th style="padding-right:0px;">system operability disruption</th>
    </tr>
    <tr>
      <th>CLIMATE.REGION</th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>Central</th>
      <td>149.0</td>
      <td>7500.5</td>
      <td>50.0</td>
      <td>96.0</td>
      <td>1410.0</td>
      <td>1687.5</td>
      <td>65.0</td>
    </tr>
    <tr>
      <th>East North Central</th>
      <td>761.0</td>
      <td>13564.0</td>
      <td>648.5</td>
      <td>1.0</td>
      <td>733.0</td>
      <td>4050.0</td>
      <td>2694.0</td>
    </tr>
    <tr>
      <th>Hawaii Region</th>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>955.0</td>
      <td>237.0</td>
    </tr>
    <tr>
      <th>Northeast</th>
      <td>159.0</td>
      <td>12240.0</td>
      <td>1.0</td>
      <td>881.0</td>
      <td>2760.0</td>
      <td>3189.0</td>
      <td>191.0</td>
    </tr>
    <tr>
      <th>Northwest</th>
      <td>702.0</td>
      <td>1.0</td>
      <td>74.0</td>
      <td>21.0</td>
      <td>898.0</td>
      <td>3507.0</td>
      <td>60.0</td>
    </tr>
    <tr>
      <th>South</th>
      <td>227.0</td>
      <td>20160.0</td>
      <td>100.0</td>
      <td>493.5</td>
      <td>422.0</td>
      <td>2100.0</td>
      <td>373.0</td>
    </tr>
    <tr>
      <th>Southeast</th>
      <td>308.5</td>
      <td>NaN</td>
      <td>95.5</td>
      <td>NaN</td>
      <td>1337.0</td>
      <td>1355.0</td>
      <td>110.0</td>
    </tr>
    <tr>
      <th>Southwest</th>
      <td>35.0</td>
      <td>76.0</td>
      <td>56.0</td>
      <td>2.0</td>
      <td>2275.0</td>
      <td>2140.0</td>
      <td>284.0</td>
    </tr>
    <tr>
      <th>West</th>
      <td>269.0</td>
      <td>882.5</td>
      <td>108.0</td>
      <td>128.5</td>
      <td>420.0</td>
      <td>975.5</td>
      <td>199.0</td>
    </tr>
    <tr>
      <th>West North Central</th>
      <td>61.0</td>
      <td>NaN</td>
      <td>0.5</td>
      <td>56.0</td>
      <td>439.5</td>
      <td>83.0</td>
      <td>NaN</td>
    </tr>
  </tbody>
</table>




<h2 id="missingness" style="scroll-margin-top: 60px;">Assessment of Missingness</h2>


<h3 id="nmar-analysis" style="scroll-margin-top: 60px;">NMAR Analysis</h3>

Two variables bear careful scrutiny: `HURRICANE.NAMES` and `DEMAND.LOSS.MW`.

**`HURRICANE.NAMES`** is missing in about 95% of rows. That pattern is not a flaw but expected: only hurricane‑related outages receive a name. The missingness is deterministically tied to `CAUSE.CATEGORY.DETAIL` and therefore is *missing by design*.

**`DEMAND.LOSS.MW`** is different. Nearly half the entries are blank, even though every outage should theoretically have a megawatt loss. Smaller utilities, especially in rural areas, often lack SCADA metering needed to quantify peak demand lost. Consequently, the absence of a value likely correlates with the unobserved magnitude itself: minor outages are less likely to be measured. This reasoning places `DEMAND.LOSS.MW` in the *not missing at random* (NMAR) category.

<h3 id="missingness-dependency" style="scroll-margin-top: 60px;">Missingness Dependency</h3>

To refine our understanding, we examined whether the missingness of `DEMAND.LOSS.MW` depends on two observed categorical features: `CAUSE.CATEGORY` and `CLIMATE.CATEGORY`. Each test used the Total Variation Distance (TVD) statistic with 1,000 permutations.

**Cause category:** The TVD between missing and present distributions is 0.1844 (p < 0.001), leading us to reject the null hypothesis of independence. Intentional attacks show up disproportionately among the missing cases, while system operability events are more prevalent when a value is recorded—consistent with the idea that smaller, localized disruptions are less likely to be metered.

<iframe src="{{ site.baseurl }}/img/plots/step3.1_missingness_cause_category.html" width="100%" height="450" frameborder="0"></iframe>

<iframe src="{{ site.baseurl }}/img/plots/step3.2_tvd_permutation_cause.html" width="100%" height="450" frameborder="0"></iframe>

**Climate category:** Here the TVD is 0.0371 with a p-value of 0.285, so we fail to reject the null. The ability to report megawatt losses does not vary systematically with the climate zone of the outage.

<iframe src="{{ site.baseurl }}/img/plots/step3.3_missingness_climate_category.html" width="100%" height="450" frameborder="0"></iframe>

<iframe src="{{ site.baseurl }}/img/plots/step3.4_tvd_permutation_climate.html" width="100%" height="450" frameborder="0"></iframe>


<table>
  <thead>
    <tr>
      <th>Column</th>
      <th>Missingness Type</th>
      <th>Takeaway</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>HURRICANE.NAMES</td>
      <td>Missing by design</td>
      <td>Names only appear for hurricane‑caused outages.</td>
    </tr>
   <tr>
      <td>DEMAND.LOSS.MW</td>
      <td>NMAR</td>
      <td>Reporting depends on utility metering, likely related to the true value.</td>
    </tr>
    <tr>
      <td>DEMAND.LOSS.MW vs. CAUSE.CATEGORY</td>
      <td>MAR conditional on cause</td>
      <td>Cause affects whether a loss is reported.</td>
    </tr>
    <tr>
      <td style="padding-right:35px;">DEMAND.LOSS.MW vs. CLIMATE.CATEGORY</td>
      <td style="padding-right:30px;">MCAR conditional on climate</td>
      <td>Climate does not influence recording.</td>
    </tr>
  </tbody>
</table>

<!--
| Column | Missingness Type | Takeaway |
| :--- | :--- | :--- |
| `HURRICANE.NAMES` | Missing by design | Names only appear for hurricane‑caused outages. |
| `DEMAND.LOSS.MW` | NMAR | Reporting depends on utility metering, likely related to the true value. |
| `DEMAND.LOSS.MW` vs. `CAUSE.CATEGORY` | MAR conditional on cause | Cause affects whether a loss is reported. |
| `DEMAND.LOSS.MW` vs. `CLIMATE.CATEGORY` | MCAR conditional on climate | Climate does not influence recording. |
-->
\
Any imputation strategy for `DEMAND.LOSS.MW` should therefore condition on outage cause but need not adjust for climate.


<h2 id="hypothesis" style="scroll-margin-top: 60px;">Hypothesis Testing: State Effects Within a Region</h2>


Our exploratory work hinted at geographic variation, but does state identity matter even when the broader grid region is fixed? If so, `U.S._STATE` is more than a proxy for NERC region and deserves explicit use in modeling.

We tested this question within the **WECC** (Western Electricity Coordinating Council), the most expansive and geographically diverse NERC region in the dataset.

### Formulating the Test

- **Null hypothesis:** Mean log‑transformed outage duration is equal across all WECC states.
- **Alternative hypothesis:** At least one state’s mean differs.
- **Method:** One‑way ANOVA on `np.log1p(OUTAGE.DURATION)` with `U.S._STATE` as the factor. States with fewer than five WECC observations were excluded.

The log transformation mitigates extreme skew and makes residuals more normal, satisfying ANOVA assumptions. The F‑statistic compares between‑state variance to within‑state variance.

### Outcome

<iframe src="{{ site.baseurl }}/img/plots/step4.1_duration_by_state_wecc.html" width="100%" height="450" frameborder="0"></iframe>


<table>
  <thead>
    <tr>
      <th style="padding-right:60px;">Source</th>
      <th style="padding-right:50px;">Sum of Squares</th>
      <th style="padding-right:60px;">df</th>
      <th style="padding-right:60px;">F</th>
      <th>p-value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>U.S._STATE</td>
      <td>309.05</td>
      <td>10</td>
      <td>5.0488</td>
      <td>0.000001</td>
    </tr>
   <tr>
      <td>Residual</td>
      <td>2479.11</td>
      <td>405</td>
    </tr>
  </tbody>
</table>

<!--

| Source | Sum of Squares | df | F | p-value |
| :--- | ---: | ---: | ---: | ---: |
| `U.S._STATE` | 309.05 | 10 | 5.0488 | 0.000001 |
| Residual | 2479.11 | 405 | | |
-->
\
The extremely small p-value leads us to reject the null hypothesis: outage durations within WECC are not homogeneous across states.

### Interpretation

California experiences notably long outages, reflecting wildfire‑related pre‑emptive shutoffs, while Utah and Colorado tend toward quicker restorations. State factors therefore contribute additional explanatory power beyond the NERC region alone. This justifies including `U.S._STATE` directly in our predictive models.

<h2 id="prediction" style="scroll-margin-top: 60px;">Framing a Prediction Problem</h2>


With state‑level effects established, we now pose a regression problem: using only information available at outage onset, how well can we predict `CUSTOMERS.AFFECTED`?

**Response variable:** the number of customers who lost power (i.e. the values in column `CUSTOMERS.AFFECTED`). Accurate early estimates of this quantity can shape operational decisions by utilities and emergency managers.

### Candidate Features

Only variables known or reliably estimable at the start of an event are allowed, avoiding any leakage from future information such as actual duration.


<table>
  <thead>
    <tr>
      <th style="padding-right:120px;">Feature</th>
      <th style="padding-right:75px;">Type</th>
      <th>Why it's admissible</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>U.S._STATE</td>
      <td>Nominal</td>
      <td>Location is immediately known; state variation matters.</td>
    </tr>
     <tr>
      <td>NERC.REGION</td>
      <td>Nominal</td>
      <td>Grid region is fixed per locality.</td>
    </tr>
    <tr>
      <td>CLIMATE.CATEGORY</td>
      <td>Nominal</td>
      <td>Climate episode is classified in real time.</td>
    </tr>
     <tr>
      <td>CAUSE.CATEGORY</td>
      <td>Nominal</td>
      <td>Initial cause is typically identified quickly.</td>
    </tr>
     <tr>
      <td>ANOMALY.LEVEL</td>
      <td>Quantitative</td>
      <td>Pre‑published climate anomaly index.</td>
    </tr>
     <tr>
      <td>POPULATION</td>
      <td>Quantitative</td>
      <td>Census data, known in advance.</td>
    </tr>
     <tr>
      <td>POPPCT_URBAN</td>
      <td>Quantitative</td>
      <td>Also from prior census.</td>
    </tr>
     <tr>
      <td>is_hurricane</td>
      <td style="padding-right:50px;">Binary categorical</td>
      <td>Detectable from weather forecasts.</td>
    </tr>
  </tbody>
</table>

<!--
| Feature | Type | Why it's admissible |
| :--- | :--- | :--- |
| `U.S._STATE` | Nominal | Location is immediately known; state variation matters. |
| `NERC.REGION` | Nominal | Grid region is fixed per locality. |
| `CLIMATE.CATEGORY` | Nominal | Climate episode is classified in real time. |
| `CAUSE.CATEGORY` | Nominal | Initial cause is typically identified quickly. |
| `ANOMALY.LEVEL` | Quantitative | Pre‑published climate anomaly index. |
| `POPULATION` | Quantitative | Census data, known in advance. |
| `POPPCT_URBAN` | Quantitative | Also from prior census. |
| `is_hurricane` | Binary | Detectable from weather forecasts. |
-->

### Evaluation Metric

We use **RMSE (Root Mean Squared Error)** in the original customer units to assess model performance, as it penalizes large misses more heavily—appropriate since underestimating a major outage has outsized consequences.

### Train/Test Split

After removing rows with missing responses or features, 1,045 observations remain (71.8% of the cleaned dataset). The target is right‑skewed (skewness 6.06), so models will use a log transformation. We allocate 80% of the data for training (836 rows) and hold 209 for testing. All tuning occurs on the training set; the test set stays unseen until final evaluation.


<h2 id="baseline" style="scroll-margin-top: 60px;">Baseline Model: Ridge Regression</h2>

### Model Choice and Encoding

Our initial benchmark is a Ridge regression on the log‑transformed `CUSTOMERS.AFFECTED`. Ridge helps manage the large number of dummy variables produced by one‑hot encoding `U.S._STATE` (about 50 columns) by shrinking coefficients toward zero, thus reducing overfitting. The log transformation tames the long right tail of the target.



<table>
  <thead>
    <tr>
      <th>Feature Type</th>
      <th>Encoding</th>
      <th>Number of Features of This Type</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="padding-right:50px;">Nominal features (U.S._STATE, NERC.REGION, CLIMATE.CATEGORY, CAUSE.CATEGORY)</td>
      <td>One‑hot</td>
      <td style="text-align:center;">4</td>
    </tr>
    <tr>
      <td>Quantitative features (ANOMALY.LEVEL, POPULATION, POPPCT_URBAN)</td>
      <td style="padding-right:50px;">StandardScaler</td>
      <td style="text-align:center;">3</td>
    </tr>
    <tr>
      <td>Binary categorical feature (is_hurricane)</td>
      <td>Pass-through (0/1)</td>
      <td style="text-align:center;">1</td>
    </tr>
     <tr>
      <td>Ordinal features (None)</td>
      <td>OrdinalEncoder</td>
      <td style="text-align:center;">0</td>
    </tr>
    <tr class="total-row">
  <td colspan="2"><strong>Total</strong></td>
  <td style="text-align:center;"><strong>8</strong></td>
</tr>
  </tbody>
</table>


<!--
| Feature | Encoding |
| :--- | :--- |
| Nominal features (`U.S._STATE`, `NERC.REGION`, `CLIMATE.CATEGORY`, `CAUSE.CATEGORY`) | One‑hot |
| Quantitative features (`ANOMALY.LEVEL`, `POPULATION`, `POPPCT_URBAN`) | StandardScaler |
| `is_hurricane` | Pass through |
-->


### Baseline Results

<!--
<iframe src="{{ site.baseurl }}/img/plots/step6.1_baseline_residuals.html" width="100%" height="450" frameborder="0"></iframe>
-->

<iframe src="{{ site.baseurl }}/img/plots/step6.2_baseline_residuals.html" width="100%" height="450" frameborder="0"></iframe>


<table>
  <thead>
    <tr>
      <th style="padding-right:60px;">Metric</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>RMSE</td>
      <td>223,420 customers</td>
    </tr>
    <tr>
      <td>R²</td>
      <td>-0.0594</td>
    </tr>
    <tr>
      <td>Test mean</td>
      <td>131,051 customers</td>
    </tr>
    <tr>
      <td>Test std</td>
      <td>217,593 customers</td>
    </tr>
  </tbody>
</table>



<!--
| Metric | Value |
| :--- | ---: |
| RMSE | 223,420 customers |
| R² | -0.0594 |
| Test mean | 131,051 customers |
| Test std | 217,593 customers |
-->

\
The baseline's RMSE slightly exceeds the test‑set standard deviation, and the negative R² indicates that the model does not outperform a constant mean predictor. In other words, the linear approximation is failing to capture the complex relationships inherent in outage severity.

### Baseline Shortcomings

Three structural limitations emerge:

- **Linearity:** The relationship between features and customer counts is far from linear; Ridge cannot accommodate sharp jumps.
- **Interactions:** Combinations such as "hurricane in a large, urban state" have outsized effects that a purely additive model cannot learn.
- **State heterogeneity:** Ridge imposes a common slope across all states, letting only intercepts vary, which is insufficient when California and Utah behave very differently.

These shortcomings motivate a switch to a more flexible, tree‑based learner and additional feature engineering.



<h2 id="final-model" style="scroll-margin-top: 60px;">Final Model: Histogram-based Gradient Boosting</h2>


### Model Setup

We adopted a Histogram‑based Gradient Boosting Regressor (HGB) on the log of `CUSTOMERS.AFFECTED`. ML trees naturally handle nonlinearity and interactions, and boosting focuses subsequent fits on the hardest cases.

Two engineered predictors augment the original feature set:

- **`log_population`:** `log1p(POPULATION)` compresses differences between small and large states, making population effects easier to model.
- **`state_pop_bin`:** A categorical variable that labels states as `small`, `medium`, or `large` based on population. This tiered grouping not only aids modeling but also forms the basis for our fairness checks.

Distribution of these bins in the data:


<table>
  <thead>
    <tr>
      <th style="padding-right:50px;">Bin</th>
      <th style="padding-right:20px;">Total</th>
      <th style="padding-right:20px;">Train</th>
      <th>Test</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Large</td>
      <td>595</td>
      <td>477</td>
      <td>118</td>
    </tr>
    <tr>
      <td>Medium</td>
        <td>362</td>
      <td>289</td>
      <td>73</td>
    </tr>
    <tr>
      <td>Small</td>
        <td>88</td>
      <td>70</td>
      <td>18</td>
    </tr>

  </tbody>
</table>


<!--
| Bin | Total | Train | Test |
| :--- | ---: | ---: | ---: |
| Large | 595 | 477 | 118 |
| Medium | 362 | 289 | 73 |
| Small | 88 | 70 | 18 |
-->



### Hyperparameter Tuning

We tuned four parameters via 5‑fold cross‑validation on the training set, optimizing RMSE back on the original scale. The search over 81 configurations yielded the following best settings:


<table>
  <thead>
    <tr>
      <th style="padding-right:50px;">Hyperparameter</th>
      <th style="padding-right:30px;">Chosen Value</th>
      <th>Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>learning_rate</td>
      <td>0.5</td>
      <td>Controls update step size.</td>
    </tr>
    <tr>
      <td>max_depth</td>
        <td>None</td>
      <td>Trees grow until leaf constraints apply.</td>
    </tr>
    <tr>
      <td>max_leaf_nodes</td>
        <td>15</td>
      <td>Limits tree complexity.</td>
    </tr>
<tr>
      <td>min_samples_leaf</td>
        <td>20</td>
      <td>Enforces smoother predictions in small groups.</td>
    </tr>
  </tbody>
</table>


<!--
| Hyperparameter | Chosen Value | Purpose |
| :--- | :--- | :--- |
| `learning_rate` | 0.05 | Controls update step size. |
| `max_depth` | None | Trees grow until leaf constraints apply. |
| `max_leaf_nodes` | 15 | Limits tree complexity. |
| `min_samples_leaf` | 20 | Enforces smoother predictions in small groups. |
-->

\
The best cross‑validated RMSE was 290,297 customers on the training folds.

### Diagnostics

The predicted vs. actual scatter plot shows tighter clustering around the 45‑degree line, especially for medium‑sized outages, indicating reduced bias compared to the baseline.

<iframe src="{{ site.baseurl }}/img/plots/step7.1_final_pred_vs_actual.html" width="100%" height="450" frameborder="0"></iframe>

Residuals versus predicted values form a more compact, symmetric band around zero than under Ridge, suggesting better calibration.

<iframe src="{{ site.baseurl }}/img/plots/step7.2_final_residuals.html" width="100%" height="450" frameborder="0"></iframe>

### Final Performance


<table>
  <thead>
    <tr>
      <th style="padding-right:50px;">Metric</th>
      <th style="padding-right:30px;">Ridge Baseline</th>
      <th style="padding-right:30px;">HGB Final</th>
      <th>Change</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>RMSE</td>
      <td>223,420</td>
        <td>213,321</td>
        <td>-10,099 (4.5% better)</td>
    </tr>
    <tr>
      <td>R²</td>
       <td>-0.0594</td>
        <td>0.0343</td>
        <td>+0.0937</td>
    </tr>
  </tbody>
</table>

<!--
| Metric | Ridge Baseline | HGB Final | Change |
| :--- | ---: | ---: | ---: |
| RMSE | 223,420 | 213,321 | -10,099 (4.5% better) |
| R² | -0.0594 | 0.0343 | +0.0937 |
-->
\
The final model reduces RMSE by roughly 10,000 customers and pushes R² into positive territory. Although the RMSE remains slightly above the test standard deviation—highlighting the inherent difficulty of the task—these gains show that nonlinear modeling and targeted features can extract useful signal from onset‑time data.


<h2 id="fairness" style="scroll-margin-top: 60px;">Fairness Analysis</h2>

### Defining Groups and Metric

We investigate whether predictive accuracy differs between states of varying population sizes. Using `state_pop_bin`, we define:

- **Group A (Large States):** average population > 8 million.
- **Group B (Small + Medium States):** average population between 0.6 and 8 million.

Accuracy is measured by RMSE on the test set, computed separately for each group.

### Hypotheses and Test

- **Null:** RMSE(A) = RMSE(B).
- **Alternative:** RMSE(A) ≠ RMSE(B).
- **Statistic:** Observed difference in RMSE between the two groups.

To evaluate this, we perform a two‑sided permutation test with 5,000 iterations, shuffling `state_pop_bin` labels across test observations while keeping predictions fixed. This isolates whether the observed gap could arise by chance.

### Results

<iframe src="{{ site.baseurl }}/img/plots/step8.1_permutation_rmse_diff.html" width="100%" height="450" frameborder="0"></iframe>



<table>
  <thead>
    <tr>
      <th style="padding-right:150px;">Group</th>
      <th>RMSE</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Large states</td>
      <td>259,518</td>
    </tr>
     <tr>
      <td>Small+Medium states</td>
      <td>131,077</td>
    </tr>
     <tr>
      <td>Observed gap</td>
      <td>128,442</td>
    </tr>
     <tr>
      <td>Two‑sided p-value</td>
      <td>0.8226</td>
    </tr>
  </tbody>
</table>

<!--
| Group | RMSE |
| :--- | ---: |
| Large states | 259,518 |
| Small+Medium states | 131,077 |
| Observed gap | 128,442 |
| Two‑sided p-value | 0.8226 |
-->
\
The high p-value means we cannot reject the null hypothesis. The RMSE difference is consistent with random label assignment given the sample size.

### Interpretation

This test does not prove the model is universally fair—it merely indicates that the apparent performance gap across population tiers is not statistically significant in this sample. Large states naturally experience more severe outages, inflating their RMSE regardless of model quality. Different fairness criteria or a larger dataset could yield different insights.


<h2 id="conclusion" style="scroll-margin-top: 60px;">Conclusion</h2>

This analysis walked through a complete pipeline—from raw outage data to a focused prediction problem and an equity check. Several themes emerged:

- **State matters:** Even within the same reliability region, outage durations differ by state, justifying state‑level features.
- **Missing data is informative:** `DEMAND.LOSS.MW` is not missing at random and its absence depends on outage cause.
- **Nonlinear modeling helps:** A Histogram‑based Gradient Boosting model with simple population engineering outperforms a Ridge baseline by about 4.5%, albeit the task remains challenging.
- **Equity appears reasonable:** A permutation test found no statistically significant RMSE disparity between large and smaller states, though this conclusion is limited by sample size.

Forecasting outage severity from onset information alone is a hard problem, given that extreme events dominate the tail and are hard to anticipate. Nonetheless, the modest improvement we achieved indicates that location, cause, and population carry actionable signal. Future work could explore richer features, larger datasets, or alternative modeling strategies to further improve early‑warning capabilities for utilities and emergency planners.
