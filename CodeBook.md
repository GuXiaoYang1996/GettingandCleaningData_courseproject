# Variables in the final data set output by run_analysis.R are as follows.  
- Subject: ID number of participated subjects
- Activity: 6 types of activities monitored  
- Other 66 variables: average of each feature on mean and standard deviation in UCI HAR Dataset for each activity and each subject

# The run_analysis.R script performs the following steps to meet the requirements as described in the course project instruction.

## 1. Load the packages used in this analysis
```
library(data.table)
library(dplyr)
library(readr)
library(tidyr)
```
## 2. Download and unzip the data files, name the folder as "UCI HAR Dataset"
```
## (ignore) setwd("C:/Users/Gu Xiaoyang/Downloads")
Url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(Url,"UCI HAR Dataset.zip",method="curl")
unzip("UCI HAR Dataset.zip")
```
## 3. Read and assign each data file to variables
`testX <- as.data.table(read.table("./UCI HAR Dataset/test/X_test.txt"))`  
- 2947 Measurements of 561 variables of test subjects  

`testY <- as.data.table(read.table("./UCI HAR Dataset/test/y_test.txt"))`  
- Labels of activities for the measurements in testX  

`testSub <- as.data.table(read.table("./UCI HAR Dataset/test/subject_test.txt"))`  
- Labels of test subjects for the measurements in testX  

`trainX <- as.data.table(read.table("./UCI HAR Dataset/train/X_train.txt"))`  
- 7352 Measurements of 561 variables of training subjects  

`trainY <- as.data.table(read.table("./UCI HAR Dataset/train/y_train.txt"))`  
- Labels of activities for the measurements in trainX  

`trainSub <- as.data.table(read.table("./UCI HAR Dataset/train/subject_train.txt"))`  
- Labels of training subjects for the measurements in trainX  

`features <- as.data.table(read.table("./UCI HAR Dataset/features.txt"))`  
- Names of the 561 variables measured  

## 4. Merge the training and the test sets (will merge allX/allMeanSD, allY, allSub in later steps)
`allX <- rbind(testX, trainX)`  
- Merge all 10299 measurements of 561 variables in testX and trainX, save in allX  

`allY <- rbind(testY, trainY)`  
- Merge all labels of activities in testY and trainY, save in allY  

`allSub <- rbind(testSub, trainSub)`  
- Merge all labels of training subjects in testSub and trainSub, save in allSub  

`names(allX) <- features$V2`  
- Name the columns in allX with the variable names provided in features

## 5. Extract only the measurements on the mean and standard deviation for each measurement
`MeanSDlabel <- grep("mean\\(\\)|std\\(\\)", features$V2)`  
- Select out all variable names containing "mean()" and "std()" (i.e. standard deviation), save their locations in MeanSDlabel  

`allMeanSD <- allX[,..MeanSDlabel]`  
- Select out the columns of "mean()" and "std()" based on their lacations (MeanSDlabel), totally 66 columns, save as a new table allMeanSD

## 6. Appropriately label the X/MeanSD data set with descriptive variable names, use full names to substitute abbreviations
```
names(allMeanSD) <- gsub("mean\\(\\)","MeanValue",names(allMeanSD)) %>%
  gsub("std\\(\\)","StandardDeviation",.) %>%
  gsub("^t","Time",.) %>%
  gsub("^f","Frequency",.) %>%
  gsub("Acc","Accelerometer",.) %>%
  gsub("Gyro","Gyroscope",.) %>%
  gsub("Mag","Magnitude",.) %>%
  gsub("BodyBody","Body",.)
```
## 7. Use descriptive activity names to name the activities in the Y data set, use the information provided in "activity_labels.txt"
```
allY$V1 <- gsub("1","WALKING",allY$V1) %>% 
  gsub("2","WALKING_UPSTAIRS",.) %>% 
  gsub("3","WALKING_DOWNSTAIRS",.) %>% 
  gsub("4","SITTING",.) %>% 
  gsub("5","STANDING",.) %>% 
  gsub("6","LAYING",.)
```
## 8. Merge X/MeanSD data set with Y and Sub data sets, and reorder by Subject and Activity
`allMeanSD_Act_Sub <- data.table(allMeanSD,"Activity"=allY$V1,"Subject"=allSub$V1)`  
- Merge the allMeanSD measurements, activity labels and subject labels together to form one data set "allMeanSD_Act_Sub"  

`allSub_Act_MeanSD <- allMeanSD_Act_Sub[,c(68,67,1:66)]`  
- Re-arrange the order of the columns so the subject label is in column 1, activity label is in column 2, the measurements of mean/std variables are in column 3:68 in the new data set allSub_Act_MeanSD  

`ordered_activity <- c("WALKING","WALKING_UPSTAIRS","WALKING_DOWNSTAIRS","SITTING","STANDING","LAYING")`  
- Assign levels for activities based on the original labels in "activity_labels.txt", so we can order them accordingly  

`allSub_Act_MeanSD$Activity <- factor(allSub_Act_MeanSD$Activity,levels=ordered_activity)`  
- Make the Activity as a factor with levels so we can order them  

`allSub_Act_MeanSD <- arrange(allSub_Act_MeanSD,Subject,Activity)`  
- Reorder the rows in allSub_Act_MeanSD by Subject number and Activity  

## 9. Create a second, independent tidy data set with the average of each variable for each activity and each subject
`allSub_Act_MeanSD_2 <- as.data.frame(mutate(allSub_Act_MeanSD, Subject_Activity=paste(as.character(Subject),Activity)))`  
- Create a new column called "Subject_Activity" which combines Subject and Activity labels (separated by " "), and is unique for each activity and each subject, save the data set as data.frame in allSub_Act_MeanSD_2  

`allMeanSD_Sub_Act_average <- as.matrix(tapply(allSub_Act_MeanSD_2[,3],allSub_Act_MeanSD_2$Subject_Activity,mean))`  
- Calculate the average of the variable in column 3 for each activity and each subject with tapply(), get 180 values, save the values (with "Subject Activity" names) as matrix in allMeanSD_Sub_Act_average  
```
for (i in 4:68){
  mean <- tapply(allSub_Act_MeanSD_2[,i],allSub_Act_MeanSD_2$Subject_Activity,mean)
  allMeanSD_Sub_Act_average <- cbind(allMeanSD_Sub_Act_average,matrix(mean))
}
```
- Calculate the average of other variables in column 4:68 for each activity and each subject with tapply() and for loop, save the result (without "Subject Activity" labels) as new columns in allMeanSD_Sub_Act_average  

`colnames(allMeanSD_Sub_Act_average) <- names(allSub_Act_MeanSD)[3:68]`  
- Name the columns of allMeanSD_Sub_Act_average with the variable names (use the column names in allSub_Act_MeanSD)  

`allSubject_Activity <- rownames(allMeanSD_Sub_Act_average)`  
- Save the row names of allMeanSD_Sub_Act_average (i.e. "Subject Activity" labels) in allSubject_Activity  
```
allMeanSD_Sub_Act_average <- as.data.table(allMeanSD_Sub_Act_average) %>% 
  mutate(Subject_Activity=allSubject_Activity) %>%
  separate(Subject_Activity,c("Subject","Activity"),sep=" ")
```
- Change allMeanSD_Sub_Act_average to data.table, add a new column called "Subject_Activity" which contains the "Subject Activity" labels, then separated that column by " " to generate Subject column and Activity column, save the data set in allMeanSD_Sub_Act_average  

`allSub_Act_MeanSD_average <- allMeanSD_Sub_Act_average[,c(67,68,1:66)]`  
- Re-arrange the columns in allMeanSD_Sub_Act_average so the subject label is in column 1, activity label is in column 2, the average values of mean/std variables are in column 3:68, save the new data set in allSub_Act_MeanSD_average  

`allSub_Act_MeanSD_average$Subject <- as.integer(allSub_Act_MeanSD_average$Subject)`  
- Change the Subject label from character to integer  

`allSub_Act_MeanSD_average$Activity <- factor(allSub_Act_MeanSD_average$Activity,levels=ordered_activity)`  
- Change the Activity label as a factor with levels as described before so we can order them  

`allSub_Act_MeanSD_average <- arrange(allSub_Act_MeanSD_average,Subject,Activity)`  
- Reorder the rows in allSub_Act_MeanSD_average by Subject number and Activity

## 10. Save the result
`write.table(allSub_Act_MeanSD_average,file="./allSub_Act_MeanSD_average_final.txt",row.name=FALSE)`  
- Export the final result allSub_Act_MeanSD_average (180 rows, 68 columns) as "allSub_Act_MeanSD_average_final.txt"  
