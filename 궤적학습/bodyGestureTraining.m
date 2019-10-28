% bodyGestureTraining.m
% 궤적 영상 학습하여 netLSTM으로 저장

% 전역 변수 선언
clear;
clc;
netCNN = googlenet;
%영상 저장 폴더 설정
dataFolder = "수화영상폴더";
%영상 전처리
[files, labels] = hmdb51Files(dataFolder);

%딥러닝 학습을 위한 설정
inputSize = netCNN.Layers(1).InputSize(1:2);
layerName = "pool5-7x7_s1";

%미리 영상을 처리한 파일이 있을 시 호출
tempFile = fullfile(tempdir,"kinect.mat");

%영상->데이터 처리
for i = 1:numFiles
    fprintf("Reading file %d of %d...\n", i, numFiles)
    
    video = readVideo(files(i));
    video = centerCrop(video,inputSize);
    sequences{i,1} = activations(netCNN,video,layerName,'OutputAs','columns');
end

%전처리 파일 저장
save(tempFile,"sequences","-v7.3");

%학습 설정
numObservations = numel(sequences);
idx = randperm(numObservations);
%학습할 데이터량 설정
N = floor(0.7 * numObservations);

%데이터 전처리
idxTrain = idx(1:N);
sequencesTrain = sequences(idxTrain);
labelsTrain = labels(idxTrain);
idxValidation = idx(N+1:end);
sequencesValidation = sequences(idxValidation);
labelsValidation = labels(idxValidation);
numObservationsTrain = numel(sequencesTrain);
sequenceLengths = zeros(1,numObservationsTrain);

for i = 1:numObservationsTrain
    sequence = sequencesTrain{i};
    sequenceLengths(i) = size(sequence,2);
end

figure
histogram(sequenceLengths)
title("Sequence Lengths")
xlabel("Sequence Length")
ylabel("Frequency")

maxLength = 400;
idx = sequenceLengths > maxLength;
sequencesTrain(idx) = [];
labelsTrain(idx) = [];

numFeatures = size(sequencesTrain{1},1);
numClasses = numel(categories(labelsTrain));

%구글넷 레이어 설정
layers = [
    sequenceInputLayer(numFeatures,'Name','sequence')
    bilstmLayer(2000,'OutputMode','last','Name','bilstm')
    dropoutLayer(0.5,'Name','drop')
    fullyConnectedLayer(numClasses,'Name','fc')
    softmaxLayer('Name','softmax')
    classificationLayer('Name','classification')];

%배치 사이즈 설정
miniBatchSize = 16;
numObservations = numel(sequencesTrain);
numIterationsPerEpoch = floor(numObservations / miniBatchSize);
numObservations
numIterationsPerEpoch

%최종 학습 설정
options = trainingOptions('adam', ...
    'MiniBatchSize',miniBatchSize, ...
    'InitialLearnRate',1e-4, ...
    'GradientThreshold',2, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{sequencesValidation,labelsValidation}, ...
    'ValidationFrequency',numIterationsPerEpoch, ...
    'Plots','training-progress', ...
    'Verbose',false);

%데이터 학습
[netLSTM,info] = trainNetwork(sequencesTrain,labelsTrain,layers,options);
%학습한 데이터를 netLSTM 파일에 저장
save('../netLSTM','netLSTM');

%기존에 학습하지 않은 데이터로 실험 
YPred = classify(netLSTM,sequencesValidation,'MiniBatchSize',miniBatchSize);
YValidation = labelsValidation;
accuracy = mean(YPred == YValidation)

%비디오 불러오는 함수
function video = readVideo(filename)

vr = VideoReader(filename);
H = vr.Height;
W = vr.Width;
C = 3;

% Preallocate video array
numFrames = floor(vr.Duration * vr.FrameRate);
video = zeros(H,W,C,numFrames);

% Read frames
i = 0;
while hasFrame(vr)
    i = i + 1;
    video(:,:,:,i) = readFrame(vr);
end

% Remove unallocated frames
if size(video,4) > i
    video(:,:,:,i+1:end) = [];
end

end


