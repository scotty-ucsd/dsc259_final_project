---
layout: page
step_number: "Step 7"
step_title: "Final Model"
permalink: /final-model/
---

## Feature Engineering
* Detail your feature engineering and hyperparameter tuning results.

* In this phase, we move beyond the raw data by creating new features designed to capture more complex relationships within our dataset.

* **New Feature 1:** `[Feature Name, e.g., 'Log-Transformed Income']`
* **Intuition:** [Explain why this helps, e.g., 'Normalizing the distribution of income helps the linear model better account for extreme outliers.']


* **New Feature 2:** `[Feature Name, e.g., 'Standardized Text Length']`
* **Intuition:** [Explain why this helps, e.g., 'Capturing the complexity of user reviews as a numerical value provides a proxy for engagement level.']



---

## Model Selection and Hyperparameter Tuning

We selected the `[Algorithm Name, e.g., Random Forest Classifier]` and used **$k$-fold cross-validation** to identify the most effective hyperparameters.

* **Hyperparameters Tested:** `[List parameters, e.g., 'max_depth': [5, 10, 15], 'n_estimators': [50, 100, 200]]`
* **Selection Method:** [e.g., `GridSearchCV` or `RandomizedSearchCV`]
* **Optimal Hyperparameters:** `[Insert best parameters found]`


---

## Final Performance Comparison

The final model was evaluated on the held-out test set to determine the actual improvement over our baseline.

| Model | Evaluation Metric (`[Metric Name]`) |
| --- | --- |
| **Baseline Model** | `[Baseline Score]` |
| **Final Model** | **`[Final Score]`** |

* **Quantifying Improvement:** [Describe how much better the final model is compared to the baseline. For example, 'The final model improved our F1-score by 12% by better capturing non-linear interactions through engineered features.']

---

## Checkpoint Questions

#### 1. Describe the new features you engineered and why you expected them to improve your model's performance.

* [Placeholder for student answer]

#### 2. What algorithm did you use for your final model, and what were the optimal hyperparameters identified during cross-validation?

* [Placeholder for student answer]

#### 3. How did your final model's performance on the test set compare to the baseline model? What does this tell you about the effectiveness of your feature engineering and tuning?

* [Placeholder for student answer]
