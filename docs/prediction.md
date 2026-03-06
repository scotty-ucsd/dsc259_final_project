---
layout: page
step_number: "Step 5"
step_title: "Framing a Prediction Problem"
permalink: /prediction/
---


## Prediction Problem and Target Variable

* In this section, we transition from exploratory analysis to predictive modeling by identifying a specific variable to forecast.

* Define your target variable and whether you are performing regression or classification.


* **Prediction Problem:** [Identify whether you are performing a **Binary Classification**, **Multiclass Classification**, or **Regression** task].
* **Target Variable (Response):** `[Insert Variable Name]`
* **Justification:** We chose this variable because [explain why predicting this specific outcome is valuable or interesting in the context of your dataset].



---

## Evaluation Metric and Performance Threshold

To assess how well our model performs, we must select a metric that aligns with our prediction goals and account for the distribution of our target variable.

* **Selected Metric:** [e.g., Accuracy, F1-Score, R-squared, or RMSE]
* **Justification:** [e.g., We chose F1-Score because our classes are imbalanced, and we want to balance precision and recall, or we chose RMSE because it penalizes large errors in our numerical predictions].


* **Baseline Expectation:** [Optional: Briefly mention what a "naive" prediction might look like, such as always predicting the mean or the majority class].

* insert images
---

## Features and Information Timing

When building a predictive model, it is crucial to ensure that the features used would actually be known at the time the prediction is made.

* **Features Used:** [List 2-3 key features you plan to use].
* **Information Availability:** At the time of prediction, we would know [describe the state of the data], so we are excluding variables like [mention any variables that would cause data leakage] to ensure our model is realistic.

---

## Checkpoint Questions

#### 1. Is your prediction problem a classification or regression task, and what specific variable are you trying to predict?

* [Placeholder for student answer]

#### 2. Which evaluation metric are you using, and why is it more appropriate for your specific problem than a standard metric like accuracy?

* [Placeholder for student answer]

#### 3. What information would you have "at the time of prediction"? Are there any variables you must exclude to avoid data leakage?

* [Placeholder for student answer]
