# MAIS202 Final Project
Cross-Species Translation

Problem Statement: 
Animal communication is a complex system that humans have yet to fully understand. While some species exhibit structured vocalization patterns, interpreting their meanings remains a challenge. This project aims to bridge that gap by developing a Cross-Species Translation Model, which will analyze animal vocalizations and generate human-readable interpretations.

# Cross-Species Bark Translation

The first step to moving toward cross-species communication is to start small.
We decided to use machine learning to decode the meaning of dog vocalizations.

---

## Introduction

Our project aims to make progress toward bridging the communication gap between humans and other animal species. By creating and fine-tuning machine learning models, our goal is to find patterns in animal speech (specifically dog barks) that humans cannot pick up on alone and associate them with a specific meaning or context, effectively beginning to “translate” animal speech.

---

## Dataset

- 693 labeled bark audio files
- Each recording is labeled by:
  - **Context** (aggression, contact, play)
  - **Breed**
  - **Dog Identity (Name)**
- We plan to scale this project using a large, multi-species vocalization dataset provided by the [Earth Species Project]([https://www.earthspecies.org/](https://github.com/earthspecies/library/tree/main)).

---

## Preprocessing & Segmentation

Before training, we segmented individual barks from longer audio files using **k-means clustering** on acoustic features.

- Bark detection was done using unsupervised clustering on spectrograms
- Consecutive bark segments were grouped into variable-length bark clips, which we then standarized to 4 seconds
- Each segment was associated with the original label from its parent file

---

## Model Architecture

We used a **Convolutional Neural Network (CNN)** with four convolutional layers.  

**Key Details:**
- Input: 4 second bark audios converted to spectrograms
- Loss function: Weighted CrossEntropyLoss to address class imbalance
- Activation: ReLU
- Optimizer: Adam
- Output: Multi-label prediction

---

## Results

| Task         | Accuracy |
|--------------|----------|
| Dog Breed    | 83%      |
| Context      | 72%      |
| Dog Identity | 67%      |

More detailed results such as confusion matrices, learning rates, and validation accuracy graphs can be found in *Final Results.pdf*.

---

## Usage

```python
# Fill in with instructions how to use
```

---

## Contributors & Acknowledgements

Students Deborah Sinishaw, Ian Gifford, and Sara Yang worked on this project while taking MAIS 202 at McGill.
We would like to thank our wonderful lecturers Shidan and Wassim and our assigned TPM, Emma.

We also credit Earth Species Project for the dataset and the inspiration behind our thinking.

Yin, S. and B. McCowan. “Barking in domestic dogs: context specificity and individual identification.” Animal Behaviour 68 (2004): 343-355.
