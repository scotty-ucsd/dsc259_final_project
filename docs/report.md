---
layout: report
title: Project Analysis Report
permalink: /report/
---

<div id="introduction"></div>
## Introduction

The **Major Power Outage Risks in the U.S.** dataset, compiled by Purdue University's LASCI research group, records 1,534 major outage events across the continental United States from January 2000 through July 2016. Each record goes well beyond a simple timestamp: the data captures climate conditions, regional geography, state-level economic indicators, and demographic profiles, giving us a rich, multidimensional view of the factors that shape outage severity and disruption.

Grid stability is a pillar of both national security and everyday modern life. The vast geographic footprint of the United States naturally produces distinct micro-regions, each with its own climate patterns, land-use characteristics, electricity demand habits, and economic profile. By combining technical outage logs with socioeconomic indicators like state gross product and urbanization percentages, we can move beyond basic event tracking toward actionable, predictive modeling of grid failures.

---

<div id="the-objective"></div>
### The Objective

**Central question:** *Can we accurately predict an outage's impact, measured by `CUSTOMERS.AFFECTED`, using only information available at the moment an outage begins?*

We chose `CUSTOMERS.AFFECTED` because it is the most direct measure of public impact. Large outages create compounding risks: households lose power, critical infrastructure strains, and emergency response systems are pushed to their limits. Providing early, reliable estimates of outage severity would let utilities and emergency managers allocate resources where they are needed most.

---

<div id="roadmap"></div>
### Roadmap

To answer this question, the report proceeds in the following stages:

1. **Data Cleaning & EDA:** Documenting the cleaning process and highlighting key patterns.
2. **Missingness Analysis:** Assessing the missingness structure of key columns like `DEMAND.LOSS.MW`.
3. **Hypothesis Testing:** Testing whether outage duration varies by state even within the same NERC reliability region, and what that implies for our features.
4. **Model Training:** Comparing a **Ridge regression** baseline against a **Histogram-based Gradient Boosting** final model.
5. **Fairness Analysis:** Examining whether the model performs equitably across states of different population sizes.

<div id="eda"></div>
## Data Cleaning and Exploratory Data Analysis

<div id="data-cleaning"></div>
### Data Cleaning

The raw dataset arrived as a formatted Excel file with metadata rows, a units row, and a redundant index column that required cleanup before any analysis could begin. After stripping the header rows and re-saving as a CSV, we loaded 1,534 records across 56 columns into a pandas DataFrame. Eight duplicate rows were removed, leaving 1,526 unique records. To manage the breadth of 56 columns, we organized every variable into seven thematic categories: Identifier, Temporal, Spatial and Climate, Outage Impact and Cause, Electricity Economics, State Economics, and Demographics and Land Use. Each category was inspected independently to identify cleaning needs.

The ten cleaning steps we applied are as follows:

1. **Drop `OBS`:** This column is a 1-indexed duplicate of the DataFrame index and adds no information.
2. **Merge start timestamps:** Combine `OUTAGE.START.DATE` and `OUTAGE.START.TIME` into a single `outage_start_dt` column.
3. **Merge restoration timestamps:** Combine `OUTAGE.RESTORATION.DATE` and `OUTAGE.RESTORATION.TIME` into `outage_restoration_dt`.
4. **Drop original date/time columns:** Remove the four source columns after merging to eliminate redundancy.
5. **Drop rows missing timestamps:** Any row without a valid start or restoration datetime is dropped to ensure duration calculations are reliable.
6. **Fill missing `CLIMATE.REGION`:** The six missing values are filled using the state name plus " Region" as a fallback label.
7. **Fill missing `CAUSE.CATEGORY.DETAIL`:** The 471 missing entries are filled with the parent `CAUSE.CATEGORY` value plus " unknown", preserving categorical structure without discarding rows.
8. **Create `is_hurricane` binary column:** A value of `True` is assigned wherever `HURRICANE.NAMES` is non-null, and `False` otherwise. The original column is then dropped.
9. **Drop missing economics rows and redundant column:** Rows missing values in the electricity economics columns are dropped, and `TOTAL.PRICE` is removed as it is derivable from other columns.
10. **Fill population density nulls with 0:** `POPDEN_UC` and `POPDEN_RURAL` are null for the District of Columbia, which is entirely urban. Filling with 0 is the correct representation rather than dropping the row.

After cleaning, the dataset retains 1,456 rows and is free of structural issues. The most consequential remaining gaps are `DEMAND.LOSS.MW` (approximately 46% missing) and `CUSTOMERS.AFFECTED` (approximately 29% missing), both of which are addressed in the Missingness section.

---

### Exploratory Data Analysis

<div id="univariate-analysis"></div>
#### Univariate Analysis

The first plot below maps outage counts across NERC reliability regions. Rather than following state lines, these regions reflect how the physical grid is organized and operated.

<iframe src="{{ site.baseurl }}/img/plots/univariate_plt3.html" width="100%" height="450" frameborder="0"></iframe>

Outage counts vary substantially across NERC regions. Some regions appear far more frequently in the dataset than others, reflecting both population density and grid exposure to weather-driven events.

The second plot shifts focus to climate regions, combining bar charts with a choropleth map to show which states drive outage totals within each environmental zone.

<iframe src="{{ site.baseurl }}/img/plots/univariate_plt4.html" width="100%" height="450" frameborder="0"></iframe>

The Northeast and South climate regions contain the largest share of outage events. Within several regions, a small number of states account for a disproportionate share of recorded outages, such as California in the West and Texas in the South.

---

<div id="bivariate-analysis"></div>
#### Bivariate Analysis

The first bivariate plot examines the relationship between climate zone and outage duration using a log-scale box plot. The log transform (log(minutes + 1)) is necessary because outage durations span from near-zero events to multi-day disruptions, and without it the largest outliers would compress all other variation into an unreadable band.

<iframe src="{{ site.baseurl }}/img/plots/bivariate_plt5.html" width="100%" height="450" frameborder="0"></iframe>

Median outage duration is fairly consistent across most climate regions, suggesting that typical restoration times do not differ dramatically by environment. However, the Northeast and South show heavier upper tails, with more extreme long-duration outliers than other regions.

The second bivariate plot groups outage duration by month to look for seasonal patterns.

<iframe src="{{ site.baseurl }}/img/plots/bivariate_plt6.html" width="100%" height="450" frameborder="0"></iframe>

Seasonal variation appears more in the spread and frequency of extreme outliers than in shifts to the median. Typical outage durations remain in a fairly narrow range across all twelve months, suggesting that while severe seasonal events can produce exceptionally long outages, they do not dramatically change how long a routine outage lasts.
<div id="missingness"></div>
## Assessment of Missingness

### NMAR Analysis

We examine two columns with significant missingness to determine their likely missingness mechanisms.

---

#### `HURRICANE.NAMES` - Missing by Design

`HURRICANE.NAMES` is approximately 95% missing. This is **Missing by Design**: a hurricane name only exists when the outage was caused by a hurricane, making the missingness entirely deterministic from `CAUSE.CATEGORY.DETAIL`. Of the 72 non-null entries, all correspond to severe weather events categorized as hurricanes, and only 2 hurricane-caused outages (0.1%) are missing a name, which is safely negligible. This column is not NMAR.

---

#### `DEMAND.LOSS.MW` - Not Missing at Random (NMAR)

`DEMAND.LOSS.MW` is approximately 46% missing. Unlike `HURRICANE.NAMES`, this column should in principle have a value for every outage. The missingness cannot be explained by design.

Our NMAR reasoning is as follows: reporting peak megawatt demand lost requires SCADA (Supervisory Control and Data Acquisition) metering infrastructure. Smaller and rural utilities frequently lack this capability. The missingness is therefore related to the unobserved value itself: small losses tend to come from small utilities that cannot measure them. To confirm this classification, we would need additional data on utility size or metering infrastructure at the time of each outage.

---

### Missingness Dependency Tests

We test whether the missingness of `DEMAND.LOSS.MW` depends on two observed categorical columns: `CAUSE.CATEGORY` and `CLIMATE.CATEGORY`. The test statistic is Total Variation Distance (TVD), computed over 1,000 permutations in each case.

---

#### Test 1: `DEMAND.LOSS.MW` Missingness vs. `CAUSE.CATEGORY`

**Null hypothesis:** The distribution of `CAUSE.CATEGORY` is the same whether `DEMAND.LOSS.MW` is missing or present.

**Alternative hypothesis:** The distribution of `CAUSE.CATEGORY` differs between missing and present rows.

<iframe src="{{ site.baseurl }}/img/plots/step3.1_missingness_cause_category.html" width="100%" height="450" frameborder="0"></iframe>

<iframe src="{{ site.baseurl }}/img/plots/step3.2_tvd_permutation_cause.html" width="100%" height="450" frameborder="0"></iframe>

With an observed TVD of 0.1844 and a p-value of 0.000, we **reject the null hypothesis** at alpha = 0.05. The missingness of `DEMAND.LOSS.MW` depends on outage cause. Intentional attacks are overrepresented among missing rows (approximately 34%) compared to present rows (approximately 22%), while system operability events are overrepresented among present rows. This makes sense: intentional attacks are typically low-scale, localized disruptions that may not trigger formal MW loss reporting.

---

#### Test 2: `DEMAND.LOSS.MW` Missingness vs. `CLIMATE.CATEGORY`

**Null hypothesis:** The distribution of `CLIMATE.CATEGORY` is the same whether `DEMAND.LOSS.MW` is missing or present.

**Alternative hypothesis:** The distribution of `CLIMATE.CATEGORY` differs between missing and present rows.

<iframe src="{{ site.baseurl }}/img/plots/step3.3_missingness_climate_category.html" width="100%" height="450" frameborder="0"></iframe>

<iframe src="{{ site.baseurl }}/img/plots/step3.4_tvd_permutation_climate.html" width="100%" height="450" frameborder="0"></iframe>

With an observed TVD of 0.0371 and a p-value of 0.285, we **fail to reject the null hypothesis** at alpha = 0.05. The missingness of `DEMAND.LOSS.MW` does not depend on climate category. While climate conditions influence whether and how severe outages become, they do not determine whether a utility can report megawatt losses.

---

### Summary

| Column | Missingness Type | Evidence |
| :--- | :--- | :--- |
| `HURRICANE.NAMES` | Missing by Design | Missingness is fully determined by outage cause; only hurricane events have a name. |
| `DEMAND.LOSS.MW` | NMAR | Missingness is linked to whether utilities can measure MW loss, which may relate to the unobserved value itself. |
| `DEMAND.LOSS.MW` vs. `CAUSE.CATEGORY` | MAR (conditional) | TVD = 0.1844, p = 0.000; missingness depends on outage cause. |
| `DEMAND.LOSS.MW` vs. `CLIMATE.CATEGORY` | MCAR (conditional) | TVD = 0.0371, p = 0.285; missingness is independent of climate. |

Any future imputation of `DEMAND.LOSS.MW` should condition on `CAUSE.CATEGORY`, since missingness depends on it, but does not need to account for `CLIMATE.CATEGORY`.

<div id="hypothesis"></div>
## Hypothesis Testing

### Does Outage Duration Vary by State Within the Same NERC Region?

Our EDA showed that outage behavior varies meaningfully across geography. But a natural question is whether that variation exists even when we hold the grid region constant. If states within the same NERC reliability region experience statistically different outage durations, it means that state-level factors matter beyond the broad regional grid classification, and that `U.S._STATE` carries real predictive signal worth including in our model.

We focus on the **WECC** (Western Electricity Coordinating Council) region because it is the largest and most geographically diverse NERC region in the dataset, spanning states from California to Montana.

---

### Hypotheses

**Null hypothesis:** The mean log-transformed `OUTAGE.DURATION` is the same across all states within the WECC region.

**Alternative hypothesis:** At least one state's mean log-transformed `OUTAGE.DURATION` differs significantly from the others within WECC.

**Significance level:** alpha = 0.05

---

### Test Design

We use a one-way ANOVA via `statsmodels.formula.api.ols`, with `U.S._STATE` as the grouping variable and log-transformed duration as the response. The F-statistic measures whether the variance in duration explained by state membership is large relative to the unexplained residual variance.

Raw `OUTAGE.DURATION` has a skewness exceeding 10, with extreme outliers above 100,000 minutes. We apply `np.log1p` to compress this long tail and bring the residual distribution closer to the normality assumption that ANOVA requires. Only states with at least 5 WECC observations are included to ensure stable group estimates.

The F-statistic is defined as:

$$
F = \frac{\text{Variance explained by state}}{\text{Residual variance}}
$$

A large F relative to the null distribution indicates that state membership explains a meaningful share of duration variation.

---

### Results

<iframe src="{{ site.baseurl }}/img/plots/step4.1_duration_by_state_wecc.html" width="100%" height="450" frameborder="0"></iframe>

| Source | Sum of Squares | df | F | p-value |
| :--- | ---: | ---: | ---: | ---: |
| `U.S._STATE` | 309.05 | 10 | 5.0488 | 0.000001 |
| Residual | 2479.11 | 405 | | |

With F = 5.0488 and p = 0.000001, we **reject the null hypothesis** at alpha = 0.05.

---

### Conclusions

Even though these states share the same physical grid under WECC, their outage durations are not statistically similar. California shows a pattern of prolonged outages, consistent with wildfire-driven safety shutoffs, while states like Utah and Colorado tend toward shorter events. Knowing the NERC region alone is not enough: state-level context carries additional explanatory power.

This result directly motivates our modeling choices in the next section. Since state lines significantly influence outage length and, by extension, outage severity, we include `U.S._STATE` as a core feature in both our baseline and final prediction models.

<div id="prediction"></div>
## Framing a Prediction Problem

Our hypothesis test confirmed that state-level factors shape outage behavior even within the same NERC reliability region. We now build on that finding by defining a formal prediction task: given only information available at or shortly after the moment an outage begins, can we estimate how many customers will be affected?

**Problem type:** Regression

**Response variable:** `CUSTOMERS.AFFECTED`, the number of utility customers who lost power during the outage. We chose this variable because it is the most direct measure of public impact and the most actionable signal for utilities and emergency planners. A reliable early estimate of customer impact allows resources to be staged before the full scope of an outage is known.

---

### Features Available at Prediction Time

We restrict our feature set to variables that are known at outage onset or are reliably pre-published. This avoids data leakage from information that would only become available after the event has fully unfolded, such as final restoration time or total outage duration.

| Feature | Type | Rationale |
| :--- | :--- | :--- |
| `U.S._STATE` | Nominal | Location is known immediately; Step 4 confirms state-level differences matter beyond grid region. |
| `NERC.REGION` | Nominal | Grid region is fixed per location. |
| `CLIMATE.CATEGORY` | Nominal | Climate episode classification is known for the period. |
| `CAUSE.CATEGORY` | Nominal | Cause is typically identified early in outage reporting. |
| `ANOMALY.LEVEL` | Quantitative | ONI-based climate anomaly index is pre-published. |
| `POPULATION` | Quantitative | State population is pre-known from census data. |
| `POPPCT_URBAN` | Quantitative | Urbanization level is pre-known from census data. |
| `is_hurricane` | Binary | Hurricane conditions are trackable in real time. |

---

### Evaluation Metric

We evaluate model performance using **RMSE (Root Mean Squared Error)**, defined as:

$$
\text{RMSE} = \sqrt{\frac{1}{n} \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}
$$

where $y_i$ is the true number of customers affected and $\hat{y}_i$ is the model's prediction. RMSE is reported in the original units of `CUSTOMERS.AFFECTED`, making it directly interpretable. We prefer RMSE over MAE here because it penalizes large errors more heavily, which is appropriate: underestimating a major outage affecting hundreds of thousands of customers is substantially worse than a comparable relative miss on a small event.

---

### Data Split

After dropping rows where `CUSTOMERS.AFFECTED` is null or any feature is missing, we retain 1,045 modeling rows from the cleaned dataset of 1,456 records (71.8% coverage). The target variable has a skewness of 6.06, reflecting the heavy right tail of outage severity. We apply an 80/20 train/test split, yielding 836 training rows and 209 test rows. All model selection and hyperparameter tuning is performed on the training set only; the test set is held out until final evaluation.

<div id="baseline"></div>
## Baseline Model

### Ridge Regression with Log-Transformed Target

Our baseline is a Ridge regression model (linear regression with L2 regularization) trained on a log-transformed version of `CUSTOMERS.AFFECTED`. We chose Ridge for two reasons. First, the target variable is heavily right-skewed, with a small number of extreme outages affecting up to 3.2 million customers. Predicting on a log scale compresses this tail so the model is not dominated by outliers. Second, one-hot encoding `U.S._STATE` alone produces roughly 50 binary columns, many of which are correlated. Ridge shrinks their coefficients rather than letting any single state dummy inflate, which helps the model generalize instead of memorizing the training data.

---

### Feature Encoding

| Feature | Type | Encoding |
| :--- | :--- | :--- |
| `U.S._STATE` | Nominal | OneHotEncoder |
| `NERC.REGION` | Nominal | OneHotEncoder |
| `CLIMATE.CATEGORY` | Nominal | OneHotEncoder |
| `CAUSE.CATEGORY` | Nominal | OneHotEncoder |
| `ANOMALY.LEVEL` | Quantitative | StandardScaler |
| `POPULATION` | Quantitative | StandardScaler |
| `POPPCT_URBAN` | Quantitative | StandardScaler |
| `is_hurricane` | Binary | Passthrough |

---

### Performance

<iframe src="{{ site.baseurl }}/img/plots/step6.1_baseline_residuals.html" width="100%" height="450" frameborder="0"></iframe>

<iframe src="{{ site.baseurl }}/img/plots/step6.2_baseline_residuals.html" width="100%" height="450" frameborder="0"></iframe>

| Metric | Value |
| :--- | ---: |
| RMSE | 223,420 customers |
| R² | -0.0594 |
| Test set mean | 131,051 customers |
| Test set std | 217,593 customers |

The baseline RMSE of 223,420 customers slightly exceeds the test set standard deviation of 217,593 customers, which means the model does not outperform simply predicting the mean for every outage. The negative R² confirms this: the Ridge model accounts for essentially none of the variance in `CUSTOMERS.AFFECTED` on held-out data.

---

### Limitations and Motivation for the Final Model

As a linear model, Ridge has three structural limitations in this setting.

First, it cannot capture non-linear jumps in outage impact. Customer counts do not scale linearly with population or cause severity, and a single linear fit cannot represent those sudden changes. Second, it cannot model combined effects: a hurricane hitting a large, dense coastal state produces far more affected customers than either factor would predict alone, but Ridge has no mechanism to learn that interaction. Third, it cannot fully learn region- and state-specific patterns. California wildfire shutoffs and Utah winter storms follow very different severity profiles, but Ridge is forced to represent all state effects as additive shifts off a common slope.

The table below summarizes how a tree-based gradient boosting approach addresses each of these failures:

| Limitation | How Gradient Boosting Addresses It |
| :--- | :--- |
| Non-linear jumps | Decision splits capture sudden spikes without assuming linearity. |
| Combined effects | Trees split on multiple features simultaneously, learning interactions like hurricane + coastal state. |
| State-specific patterns | Local decision rules create different behavior for different regions without a shared slope assumption. |
| Skewed target | Boosting focuses correction steps on large residuals, reducing the influence of extreme outliers. |

To support the more expressive model, we also engineer two additional features: `log_population`, which compresses the scale gap between small states like Wyoming (approximately 0.6 million) and large ones like California (approximately 37 million), and `state_pop_bin`, which groups states into small, medium, and large population buckets so the model can learn distinct patterns for each tier. These features and the full tuning procedure are described in the Final Model section.

<div id="final-model"></div>
## Final Model
### Overview

We replaced the linear Ridge baseline with a Histogram-based Gradient Boosting Regressor (HGB) trained on a log-transformed `CUSTOMERS.AFFECTED` target. This approach captures non-linear relationships and interaction effects that Ridge cannot represent, while predictions are still evaluated in the original customer units by applying the inverse transform after prediction.

The final model uses the same eight core predictors as the baseline and adds two engineered features:

- **`log_population`:** Defined as `log1p(POPULATION)`, this compresses the large scale gap between small states like Wyoming (approximately 0.6 million residents) and large ones like California (approximately 37 million), making population effects more linear on the log scale.
- **`state_pop_bin`:** Groups each state into a `small`, `medium`, or `large` population bucket based on its average census population. This allows the model to learn distinct severity patterns for each population tier and also serves as the grouping variable in our fairness analysis.

The distribution of `state_pop_bin` across the modeling dataset is shown below:

| Bin | Total | Train | Test |
| :--- | ---: | ---: | ---: |
| Large | 595 | 477 | 118 |
| Medium | 362 | 289 | 73 |
| Small | 88 | 70 | 18 |

---

### Hyperparameter Tuning

We tuned four capacity-controlling hyperparameters using 5-fold cross-validation with a custom RMSE scorer evaluated on the original `CUSTOMERS.AFFECTED` scale. The search evaluated 81 candidate configurations (405 total fits) and selected the configuration that minimized cross-validated RMSE on the training set.

| Hyperparameter | Selected Value | Role |
| :--- | :--- | :--- |
| `learning_rate` | 0.05 | Controls step size per boosting iteration; lower values produce more stable ensembles. |
| `max_depth` | None | No depth limit; trees grow until stopped by leaf constraints. |
| `max_leaf_nodes` | 15 | Caps tree complexity, preventing overfitting to rare outage patterns. |
| `min_samples_leaf` | 20 | Requires at least 20 samples per leaf, smoothing predictions for small state groups. |

Best cross-validated RMSE on the training set: 290,297 customers.

---

### Diagnostic Plots

The Predicted vs. Actual plot below shows each test set outage as a point, with a dashed 45-degree reference line indicating perfect prediction. Compared to the baseline, points cluster closer to the diagonal for medium-sized outages, reflecting reduced systematic under- and over-prediction.

<iframe src="{{ site.baseurl }}/img/plots/step7.1_final_pred_vs_actual.html" width="100%" height="450" frameborder="0"></iframe>

The Residual vs. Predicted plot graphs (Actual - Predicted) against the predicted value. The final model shows a tighter, more symmetric band of residuals around zero than the Ridge baseline, indicating better calibration across the range of predicted outage sizes.

<iframe src="{{ site.baseurl }}/img/plots/step7.2_final_residuals.html" width="100%" height="450" frameborder="0"></iframe>

---

### Results

| Metric | Baseline (Ridge) | Final (HGB) | Improvement |
| :--- | ---: | ---: | ---: |
| RMSE | 223,420 customers | 213,321 customers | -10,099 customers |
| R-squared | -0.0594 | 0.0343 | +0.0937 |
| Relative RMSE reduction | | | 4.5% |

The final model achieves an RMSE of 213,321 customers on the held-out test set, a reduction of 10,099 customers (4.5%) over the baseline, and shifts R-squared from negative to slightly positive. The RMSE still exceeds the test set standard deviation of 217,593 customers, which reflects the inherent difficulty of the prediction task: outage severity is highly skewed and driven by rare, extreme events that are hard to anticipate from onset-time features alone. The engineered population features and tree-based architecture nonetheless produce a measurable and meaningful improvement over the linear baseline.

<div id="fairness"></div>
## Fairness Analysis
### Groups and Metric

We examine whether the final model is equally accurate for outages in large-population states versus smaller ones. Using the engineered feature `state_pop_bin`, we define two groups:

- **Group A (Large States):** States with an average population above 8 million.
- **Group B (Small and Medium States):** States with an average population between approximately 0.6 and 8 million.

Our fairness metric is the group-wise RMSE of the final model on the held-out test set, computed separately for each group in the original `CUSTOMERS.AFFECTED` units.

---

### Hypotheses

**Null hypothesis:** The model's RMSE is the same for large and smaller states: RMSE(A) = RMSE(B).

**Alternative hypothesis:** The model's RMSE differs between the two groups: RMSE(A) != RMSE(B).

**Significance level:** alpha = 0.05

**Test statistic:**

$$
T_{\text{obs}} = \text{RMSE}_{\text{large}} - \text{RMSE}_{\text{small+medium}}
$$

---

### Permutation Procedure

We use a two-sided permutation test with 5,000 iterations. In each iteration, we randomly shuffle the `state_pop_bin` labels across test set observations, recompute RMSE for each randomized group, and record the difference. This breaks any real-world link between state size and prediction error while preserving the joint distribution of predictions and true values. The two-sided p-value is the proportion of permuted differences whose absolute value meets or exceeds the observed absolute difference.

Shuffling labels rather than re-fitting the model keeps the trained model and its predictions fixed, so the test directly answers whether the observed RMSE gap could arise from random variation in group membership alone.

---

### Results

<iframe src="{{ site.baseurl }}/img/plots/step8.1_permutation_rmse_diff.html" width="100%" height="450" frameborder="0"></iframe>

| Group | RMSE |
| :--- | ---: |
| Group A (Large States) | 259,518 customers |
| Group B (Small and Medium States) | 131,077 customers |
| Observed difference | 128,442 customers |
| Two-sided p-value | 0.8226 |

---

### Conclusion

The two-sided permutation p-value is 0.8226, well above alpha = 0.05. We fail to reject the null hypothesis. The observed RMSE gap of 128,442 customers between large and small/medium states is consistent with what we would expect from random variation in group membership under the null model.

This does not mean the model is definitively fair in every sense. Large states contain more high-severity outages by nature, which makes their RMSE harder to minimize regardless of model quality. What this test tells us is that the RMSE gap we observed is not statistically distinguishable from noise given our test set size. A larger or differently composed test set could yield a different conclusion, and other fairness criteria beyond RMSE parity may still reveal disparities worth investigating.

---

<div id="closing"></div>
## Closing Remarks

This project developed an end-to-end analysis of major U.S. power outages, moving from raw data cleaning through exploratory analysis, missingness assessment, hypothesis testing, predictive modeling, and fairness evaluation.

A few key findings stand out across the pipeline. First, outage behavior varies significantly by state even within the same NERC reliability region, a result that directly motivated including `U.S._STATE` as a core predictor rather than relying on grid region alone. Second, the missingness of `DEMAND.LOSS.MW` is not random: it depends on outage cause, which has real implications for any future imputation or analysis that relies on that column. Third, a Histogram-based Gradient Boosting model with engineered population features outperformed the Ridge regression baseline on held-out data, reducing RMSE by 4.5% and shifting R-squared from negative to slightly positive. Finally, a permutation-based fairness analysis found no statistically significant evidence that model RMSE differed across state population tiers, though we note that the absence of statistical significance on a test set of 209 rows is not the same as a guarantee of fairness.

Predicting outage severity from onset-time information alone remains a genuinely hard problem. Outage impact is driven by rare, extreme events that are difficult to anticipate before they fully unfold, and the features available at prediction time capture only a fraction of the variance in `CUSTOMERS.AFFECTED`. The modest but real improvement of the final model over a mean-prediction baseline suggests there is signal in location, cause, and population structure, and that richer feature engineering or larger training sets could push performance further.

We hope this analysis serves as a useful starting point for thinking about how data-driven tools might support utility planning and emergency response in the face of an aging grid and increasingly severe weather events.
