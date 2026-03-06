---
layout: page
step_number: "Step 6"
step_title: "Baseline Model"
permalink: /baseline/
---

Describe your initial model, the features used (quantitative vs nominal), and its performance.

---

## layout: page step_number: "Step 6" step_title: "Baseline Model" permalink: /baseline/

## Model Description and Preprocessing

In this step, we implement a simple baseline model to establish a performance floor for our prediction task.

* **Model Type:** [e.g., Linear Regression, Logistic Regression, or a basic Decision Tree]
* **Features Used:**
* **Quantitative:** `[List quantitative features, e.g., 'Age', 'Income']`
* **Ordinal:** `[List ordinal features, e.g., 'Education Level', 'Rating']`
* **Nominal:** `[List nominal features, e.g., 'City', 'Gender']`


* **Preprocessing Pipeline:** [Describe how you handled different data types. For example, "We utilized a `scikit-learn` Pipeline to apply One-Hot Encoding to our nominal features while keeping quantitative features as-is."]

---

## Baseline Performance

We split the data into training and testing sets to evaluate how well our model generalizes to unseen data.

* **Evaluation Metric:** `[Insert Metric from Step 5, e.g., F1-Score or RMSE]`
* **Test Score:** `[Insert Value]`

* insert imgs
---

## Model Evaluation

* **Is it "Good"?** [State whether you believe this performance is acceptable for a baseline.]
* **Justification:** [Compare your score to a simple heuristic, such as the majority class accuracy or the mean value of the target, to justify why this model is or is not a strong starting point.]

---

## Checkpoint Questions

#### 1. List the features in your baseline model and classify each as quantitative, ordinal, or nominal.

* [Placeholder for student answer]

#### 2. What is your model's performance on the test set, and do you consider this model "good"? Why or why not?

* [Placeholder for student answer]

#### 3. Describe the preprocessing steps you took (e.g., One-Hot Encoding) to prepare your features for the model.

* [Placeholder for student answer]
