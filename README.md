# CarryTranslator
키넥트와 매트랩을 활용한 청각 장애인을 위한 수화 통역 시스템

# 실행전 준비물
MATLAB, Kinect v1, kinect SDK v1.8 설치

# MATLAB 애드온
Image Acquisition Toolbox Support Package for Kinect for Windows Sensor
Image Acquisition Toolbox
Computer Vision Toolbox
Deep Learning Toolbox
Deep Learning Toolbox Model for GoogLeNet Network
Audio Toolbox
speech2text
text2speech

#실행방법
guiRun.m 실행

#학습 데이터 생성방법
궤적학습 시 - 궤적학습폴더의 bodyGestureDataset에 *90* 번 라인 파일명 저장
지화학습 시 - 지화학습폴더의 handGestureDataset에 *98* 번 라인 파일명 저장

#학습 방법
각폴더의 ____GestureTraining 실행
**지화 학습** 시 *net* 파일 생성
**궤적 학습** 시 *netLSTM* 파일 생성
