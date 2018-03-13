# NaiveBayesClassifier

This program implements a Naive Bayes classifier that can be used to classify data titled predict.txt using training data titled training.txt.
This classifier assumes that there are two classes to classify (responders and non-responders for example) and that there is at least one record of each class in the training data.

This classifier currently only considers categorical data but can be adapted to use continuous variables as well.

The classifier also uses a Pearson's chi-squared test on each category to see if it is significant to use in the classification.
