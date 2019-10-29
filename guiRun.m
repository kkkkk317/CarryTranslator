% guiRun.m
% 수화 인식 프로그램 실행

% 지화 학습 결과 load
load net

% 궤적 학습 결과 load
load netLSTM

% load한 net으로 수화 인식 프로그램 실행
translator(net, netLSTM)
