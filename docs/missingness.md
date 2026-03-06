---
layout: page
step_number: "Step 3"
step_title: "Assessment of Missingness"
permalink: /missingness/
---

## NMAR Analysis
To determine if a column is **NMAR**, we must consider the underlying process. 

---

## Missingness Dependency
In this section, we analyze whether the missingness of **[Selected Column]** 

### 1. Significant Dependency: [Selected Column] vs. [Column A]
We tested if the missingness of **[Selected Column]** depends on **[Column A]**.
* **Test Statistic:** [Insert Test Statistic]
* **Significance Level:** 0.05
* **Observed Statistic:** [Insert Value]
* **P-Value:** [Insert Value]

**Interpretation:** Since the p-value is [lower/higher] than 0.05, we [reject/fail to reject] the null hypothesis. This suggests that the missingness of [Selected Column] **is dependent** on [Column A], making it **MAR**.

*insert plot here*

---

### 2. No Significant Dependency: [Selected Column] vs. [Column B]
We also tested the dependency of **[Selected Column]** missingness on **[Column B, e.g., YEAR]**.
* **Test Statistic:** [e.g., Difference in Means]
* **Significance Level:** 0.05
* **Observed Statistic:** [Insert Value]
* **P-Value:** [Insert Value]

**Interpretation:** With a p-value of [Insert Value], we **fail to reject** the null hypothesis. This indicates that the missingness of [Selected Column] does **not** appear to depend on [Column B].

*insert plot here*

---

## Checkpoint Questions

#### 1. NMAR vs. MAR
The core difference lies in whether the "reason" for missingness is contained within our observed data. By performing permutation tests, we moved [Selected Column] from a state of unknown missingness to MAR by proving its dependency on [Column A].

#### 2. Permutation Test Interpretation
The empirical distribution of our test statistic shows that our observed difference is [extreme / typical]. This statistical evidence allows us to conclude that... [finalize your interpretation here]. 
