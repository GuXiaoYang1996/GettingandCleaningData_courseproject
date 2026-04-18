# Load packages
library(data.table)
library(dplyr)
library(readr)
library(tidyr)

# Download and read data files
## (ignore) setwd("C:/Users/Gu Xiaoyang/Downloads")
Url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(Url,"UCI HAR Dataset.zip",method="curl")
unzip("UCI HAR Dataset.zip")
testX <- as.data.table(read.table("./UCI HAR Dataset/test/X_test.txt"))
testY <- as.data.table(read.table("./UCI HAR Dataset/test/y_test.txt"))
testSub <- as.data.table(read.table("./UCI HAR Dataset/test/subject_test.txt"))
trainX <- as.data.table(read.table("./UCI HAR Dataset/train/X_train.txt"))
trainY <- as.data.table(read.table("./UCI HAR Dataset/train/y_train.txt"))
trainSub <- as.data.table(read.table("./UCI HAR Dataset/train/subject_train.txt"))
features <- as.data.table(read.table("./UCI HAR Dataset/features.txt"))

# Merge the training and the test sets (will merge allX/allMeanSD, allY, allSub in later steps)
allX <- rbind(testX, trainX)
allY <- rbind(testY, trainY)
allSub <- rbind(testSub, trainSub)
names(allX) <- features$V2

# Extract only the measurements on the mean and standard deviation for each measurement
MeanSDlabel <- grep("mean\\(\\)|std\\(\\)", features$V2)
allMeanSD <- allX[,..MeanSDlabel]

# Appropriately label the X/MeanSD data set with descriptive variable names
names(allMeanSD) <- gsub("mean\\(\\)","MeanValue",names(allMeanSD)) %>%
  gsub("std\\(\\)","StandardDeviation",.) %>%
  gsub("^t","Time",.) %>%
  gsub("^f","Frequency",.) %>%
  gsub("Acc","Accelerometer",.) %>%
  gsub("Gyro","Gyroscope",.) %>%
  gsub("Mag","Magnitude",.) %>%
  gsub("BodyBody","Body",.)

# Use descriptive activity names to name the activities in the Y data set
allY$V1 <- gsub("1","WALKING",allY$V1) %>% 
  gsub("2","WALKING_UPSTAIRS",.) %>% 
  gsub("3","WALKING_DOWNSTAIRS",.) %>% 
  gsub("4","SITTING",.) %>% 
  gsub("5","STANDING",.) %>% 
  gsub("6","LAYING",.)

# Merge X/MeanSD data set with Y and Sub data sets, and reorder by Subject and Activity
allMeanSD_Act_Sub <- data.table(allMeanSD,"Activity"=allY$V1,"Subject"=allSub$V1)
allSub_Act_MeanSD <- allMeanSD_Act_Sub[,c(68,67,1:66)]
ordered_activity <- c("WALKING","WALKING_UPSTAIRS","WALKING_DOWNSTAIRS","SITTING","STANDING","LAYING")
allSub_Act_MeanSD$Activity <- factor(allSub_Act_MeanSD$Activity,levels=ordered_activity)
allSub_Act_MeanSD <- arrange(allSub_Act_MeanSD,Subject,Activity)

# Create a second, independent tidy data set with the average of each variable for each activity and each subject
allSub_Act_MeanSD_2 <- as.data.frame(mutate(allSub_Act_MeanSD, Subject_Activity=paste(as.character(Subject),Activity)))
allMeanSD_Sub_Act_average <- as.matrix(tapply(allSub_Act_MeanSD_2[,3],allSub_Act_MeanSD_2$Subject_Activity,mean))
for (i in 4:68){
  mean <- tapply(allSub_Act_MeanSD_2[,i],allSub_Act_MeanSD_2$Subject_Activity,mean)
  allMeanSD_Sub_Act_average <- cbind(allMeanSD_Sub_Act_average,matrix(mean))
}
colnames(allMeanSD_Sub_Act_average) <- names(allSub_Act_MeanSD)[3:68]
allSubject_Activity <- rownames(allMeanSD_Sub_Act_average)
allMeanSD_Sub_Act_average <- as.data.table(allMeanSD_Sub_Act_average) %>% 
  mutate(Subject_Activity=allSubject_Activity) %>%
  separate(Subject_Activity,c("Subject","Activity"),sep=" ")
allSub_Act_MeanSD_average <- allMeanSD_Sub_Act_average[,c(67,68,1:66)]
allSub_Act_MeanSD_average$Subject <- as.integer(allSub_Act_MeanSD_average$Subject)
allSub_Act_MeanSD_average$Activity <- factor(allSub_Act_MeanSD_average$Activity,levels=ordered_activity)
allSub_Act_MeanSD_average <- arrange(allSub_Act_MeanSD_average,Subject,Activity)

# Save the result
write.table(allSub_Act_MeanSD_average,file="./allSub_Act_MeanSD_average_final.txt",row.name=FALSE)