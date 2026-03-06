---
layout: page
step_number: "Step 4"
step_title: "Hypothesis Testing"
permalink: /hypothesis/
---

## Framing the Question
*Clearly state a pair of hypotheses and perform a hypothesis test or permutation test that is not related to missingness. Feel free to use one of the example questions stated in the “Example Questions and Prediction Problems” section of your dataset’s description page or pose a hypothesis test of your own*

### The Hypotheses
* **Null Hypothesis ($H_0$):** In the population, the [Outcome] for [Group A] and [Group B] come from the same distribution, and any observed difference in our sample is due to random chance.
* **Alternative Hypothesis ($H_1$):** In the population, the [Outcome] for [Group A] is significantly [greater/less/different] than [Group B]. The observed difference is unlikely to have occurred by chance alone.

---

## Test Statistic and Significance Level
To evaluate these hypotheses, we must choose a metric that best captures the difference between our groups.

* **Test Statistic:** [e.g., Difference in Sample Means or Total Variation Distance]
    * **Justification:** We chose this statistic because [e.g., it effectively measures the shift in central tendency between two numerical distributions].
* **Significance Level ($\alpha$):** 0.05
    * **Justification:** A 5% significance level is a standard threshold in exploratory data science to balance the risk of Type I and Type II errors.

---

## Permutation Test and Results
We conducted a **permutation test** by shuffling the group labels 10,000 times to simulate the distribution of the test statistic under the null hypothesis.

* **P-Value:** [Insert Value, e.g., 0.024]
* **Observed Statistic:** [Insert Value]

*add plot here*

---

## Checkpoint Questions
*add checkpoint list here*
