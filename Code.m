trainingData = readtable('training.txt');
testingData = readtable('predict.txt');

resultsTable = testingData(:, 1:2);

%training

%Array indicating significant variables
significance = zeros(width(trainingData), 1);

%class of responders and nonresponders
class1 = trainingData(strcmp(trainingData.Responder___, 'TRUE'),:);
class2 = trainingData(strcmp(trainingData.Responder___, 'FALSE'),:);

%calculate priors
prior1 = height(class1)/height(trainingData);
prior2 = height(class2)/height(trainingData);

%table to hold categories
categories = cell(width(trainingData),height(trainingData));

%Get all unique category names and densities, skipping the first two columns(because it is id and respondent)
for i=3:width(trainingData)
    %fill in new column to categories array
    categories{i} = unique(trainingData{:,i});
    
    chiTestStatistic = 0;
    
    for j=1:length(categories{i})
        %perform a chi square test to see if this category is a
        %statistically significant predictor of response
        class1Var = height(class1(strcmp(class1{:,i}, categories{i}{j}),:));
        class2Var = height(class2(strcmp(class2{:,i}, categories{i}{j}),:));
        
        class1Expected = prior1 * (class1Var + class2Var);
        class2Expected = prior2 * (class1Var + class2Var);
        
        chiTestStatistic = chiTestStatistic + (class1Var - class1Expected)^2 / class1Expected;
        chiTestStatistic = chiTestStatistic + (class2Var - class2Expected)^2 / class2Expected;
        
        categories{i}{j, 2} = class1Var/height(class1);
        categories{i}{j, 3} = class2Var/height(class2);
    end
    
    %if it is significant, add the category to the analysis
    %degreesOfFreedom is (categories - 1) * (classes - 1) but since there
    %are always two classes, it simplfies to just (categories - 1)
    if (chi2cdf(chiTestStatistic, length(categories{i}) - 1) > 0.95)
        fprintf("Variable: %s is significant\n", trainingData.Properties.VariableNames{i});
        significance(i) = 1;
    end
end

%testing

class1correct = 0;
class1wrong = 0;
class2correct = 0;
class2wrong = 0;

for i = 1:height(testingData)
    %intialize posteriors to the priors
    post1 = prior1;
    post2 = prior2;
    
    for j = 3:width(testingData(i,:))
        %if the variable is significant and it is found in the training
        %data, then score it
        if (significance(j) == 1 && not(isempty(categories{j}(strcmp(categories{j}(:,1),testingData{i,j}),:))))
            post1 = post1 * categories{j}{strcmp(categories{j}(:,1),testingData{i,j}),2};
            post2 = post2 * categories{j}{strcmp(categories{j}(:,1),testingData{i,j}),3};
        end
    end
    resultsTable{i,2} = {post1/(post1 + post2)};
    %{
    if (strcmp(testingData{i,2}, 'TRUE'))
        if (post1 > post2)
            class1correct = class2correct + 1;
        else
            class1wrong = class1wrong + 1;
        end
    elseif (strcmp(testingData{i,2}, 'FALSE'))
        if (post1 < post2)
            class2correct = class2correct + 1;
        else
            class2wrong = class2wrong + 1;
        end
    end
    %}
end

writetable(resultsTable, 'RESULTS.csv');

class1Accuracy = class1correct/(class1correct+class1wrong);
class2Accuracy = class2correct/(class2correct+class2wrong);

disp("Results");
%fprintf("Accuracy for Responders:%d for Non-Responders:%d\n", class1Accuracy, class2Accuracy);
%fprintf("Adjusted total Accuracy:%d\n", (class1Accuracy+class2Accuracy)/2);