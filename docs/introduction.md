---
layout: page
step_number: "Step 1"
step_title: "Introduction"
permalink: /introduction/
---

## Background
* This dataset is provided by the Laboratory for Advancing Sustainable Critical Infrastructure at Purdue University.
* It documents major power outages across the continental U.S.
* Beyond outage specifics, the data covers:
    * **Geographical location** and **land-use characteristics**.
    * **Climatic information** and regional weather patterns.
    * **Electricity consumption** and **economic characteristics** of affected states.

---

## Brief Description
* An initial look at the raw data revealed an irregular structure unsuitable for direct analysis.

<div class="text-center" style="margin: 30px 0;">
    <img src="{{ site.baseurl }}/img/data_preview.png" class="img-responsive center-block" alt="Raw Data Preview" style="border: 1px solid #ddd; border-radius: 4px;">
    <p class="text-muted" style="margin-top: 10px;"><em>Figure 1: The original Excel formatting includes metadata rows and non-standard headers.</em></p>
</div>

* Because the Excel sheet was designed for human interaction rather than machine reading, we must standardize it into a clean `.csv` format. 
* **Key Formatting Issues:**
    1. **Column 1:** Contains metadata that is not relevant to our analysis.
    2. **Row Offset:** The column headers begin on the 6th row, while actual data observations start on row 8.
    3. **Units:** The 7th row contains unit descriptions (e.g., Megawatts, Dollars) which interfere with data types.

---

## Checkpoint Questions

#### 1. Describe your dataset 
*See Background and Brief Description sections above.*

#### 2. What is the central question you are answering?
* [Insert potential specific research question here]
* **IMPORTANT** DEFINE QUESTION THIS IS FIRST IN DATA SCIENCE LIFE CYCLE **IMPORTANT** 

#### 3. Why does power outage risk matter?
* [Insert your reasoning here]
