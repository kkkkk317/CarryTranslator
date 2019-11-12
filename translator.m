% translator.m
% GUI 기반 수화인식 프로그램


function translator(net, netLSTM)
%데이터 저장할 자바 연결리스트 생성
import java.util.LinkedList
q = LinkedList();
%초성 중성 종성의 값
cho1  = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18];
jung1 = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
jong1 = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27];
%전역 변수 선언
temp1 = [];
temp2 = 0;
temp3 = [""];
countT = 1;
accuracyR = ["a", "b"];
clear k;
global k;
m = 0;

% googleNet input 설정
netCNN = googlenet;
inputSize = netCNN.Layers(1).InputSize(1:2);
layerName = "pool5-7x7_s1";

% 키넥트 초기화
colorVid = videoinput('kinect', 1);
depthVid = videoinput('kinect', 2);

% 스켈레톤 인식을 위한 depth 캠
triggerconfig(depthVid, 'manual');
depthVid.FramesPerTrigger = 1;
depthVid.TriggerRepeat = inf;
set(getselectedsource(depthVid), 'TrackingMode', 'Skeleton');

% color 캠 초기화
triggerconfig(colorVid, 'manual');
colorVid.FramesPerTrigger = 1;
colorVid.TriggerRepeat = inf;

% 함수를 위한 타이머 설정
t2 = timer('Period', 0.1,'ExecutionMode', 'fixedRate');
t2.TimerFcn = @dispDepth2;
t = timer('Period', 0.1,'ExecutionMode', 'fixedRate');
t.TimerFcn = @dispDepth;
t3 = timer('Period', 10,'ExecutionMode', 'fixedRate');
t3.TimerFcn = @speechfc;

% GUI 프레임워크 설정
window=figure('Color',[0, 0, 0],'Name','Depth Camera',...
    'DockControl','off','Units','Pixels',...
    'toolbar','none',...
    'Position',[50 50 800 600]);
padd = uicontrol('Parent',window,'Style','text');
set(padd,'String',' ','position',[70 120 670 140])
padd.BackgroundColor = [1, 0.55 , 0];
% 수화 번역 결과창 설정
b = uicontrol('Parent',window,'Style','text');
set(b,'String','수화 합침 결과','position',[80 130 650 120])
b.BackgroundColor = [1, 1 , 1];
b.ForegroundColor = 'black';
b.FontName = 'Dotum';
b.FontSize = 30;
b.FontWeight = 'bold';

d = uicontrol('Parent',window,'Style','text');
set(d,'String','수화,지화 번역 결과','position',[420 440 320 120])
d.BackgroundColor = [1, 1 , 1];
d.ForegroundColor = 'black';
d.FontName = 'Dotum';
d.FontSize = 38;
d.FontWeight = 'bold';

% STT 결과창 설정
c = uicontrol('Parent',window,'Style','text');
set(c,'String','음성 인식 결과','position',[420 290 320 120])
c.BackgroundColor = [1, 1 , 1];
c.ForegroundColor = 'black';
c.FontName = 'Dotum';
c.FontSize = 30;
c.FontWeight = 'bold';

% 지화를 인식하기 위한 버튼 설정
startb1=uicontrol('Parent',window,'Style','pushbutton','String',...
    '지화',...
    'FontSize',20 ,...
    'Units','normalized',...
    'Position',[0.08 0.04 0.2 0.13],...
    'Callback',@startCallback);
startb1.FontWeight = 'bold';


% 궤적을 인식하기 위한 버튼 설정
startb=uicontrol('Parent',window,'Style','pushbutton','String',...
    '수화',...
    'FontSize',20 ,...
    'Units','normalized',...
    'Position',[0.295 0.04 0.2 0.13],...
    'Callback',@startCallback2);
startb.FontWeight = 'bold';

% 프로그램을 멈추기 위한 버튼 설정
stopb=uicontrol('Parent',window,'Style','pushbutton','String',...
    'STOP',...
    'FontSize',20 ,...
    'Units','normalized',...
    'Position',[0.51 0.04 0.2 0.13],...
    'Callback',@stopCallback);
stopb.FontWeight = 'bold';

% 음성 인식을 하기 위한 버튼 설정
speechb=uicontrol('Parent',window,'Style','pushbutton','String',...
    '말하기',...
    'FontSize',20 ,...
    'Units','normalized',...
    'Position',[0.725 0.04 0.2 0.13],...
    'Callback',@speechCallback);
speechb.BackgroundColor = '#ff8c00';
speechb.ForegroundColor = 'white';
speechb.FontWeight = 'bold';

% 스피치 함수 선언
    function speechfc(obj, event)
        % 녹음 시작
        recObj = audiorecorder(44100, 16, 1);
        speechObject = speechClient('Google','languageCode','ko-KR');
        disp('Start speaking.')
        recordblocking(recObj, 5);
        disp('End of Recording.')
        
        % 녹음한 음성을 파일로 저장후 load
        filename = 'sample.wav';
        y = getaudiodata(recObj);
        audiowrite(filename, y, 48000);
        [samples, fs] = audioread('sample.wav');
        
        % 음성 파일을 STT로 내보냄
        outInfo = speech2text(speechObject, samples, fs);
        result = outInfo.Transcript;
        set(c,'String', result,'position',[420 290 320 120])
    end

% 지화 함수
    function dispDepth(obj, event)
        
        % 영상 출력(0~4096 로 프레임 재지정)
        trigger(depthVid);
        trigger(colorVid);
        [depthMap, ~, depthMetaData] = getdata(depthVid);
        [colorFrameData] = getdata(colorVid);
        idx = find(depthMetaData.IsSkeletonTracked);
        ax = subplot(2,2,1);
        set(ax, 'position', [0.09,0.43 0.41 0.55]);
        imshow(colorFrameData);
        
        % 영상 처리
        % 스켈레톤 추적이 됐을 때
        if idx ~= 0
            % 오른손 위치 추적
            rightHand = depthMetaData.JointDepthIndices(12,:,idx);
            
            % 오른손 데이터값 추출
            zCoord = 1e3*min(depthMetaData.JointWorldCoordinates(12,:,idx));
            radius = round(90 - zCoord / 50);
            rightHandBox = [rightHand-0.5*radius 1.2*radius 1.2*radius];
            
            % 사각형으로 오른손 크롭
            rectangle('position', rightHandBox, 'EdgeColor', [1 1 0]);
            handDepthImage = imcrop(colorFrameData,rightHandBox);
            
            % 데이터 추출이 됐을 때
            if ~isempty(handDepthImage)
                temp = imresize(handDepthImage, [224 224]);
                
                % 구글넷을 활용한 결과 예측
                YPred = classify(net,temp);
                result = string(YPred);
                
                accuracyR(countT) = result;
                %합침을 뜻하는 ㅃ이 들어오면 초 중 종성 계산 및 데이터 저장
                if result == 'ㅃ'
                    q.add('!');
                    q.add('@');
                    for j=1:6
                        if q.get(0)=='!'
                            break;
                        elseif q.get(0)~='!'
                            temp1(j)=0;
                        end
                        for i=0:q.size()-1
                            if q.size() == 2 || q.size() == 1
                                break
                            end
                            if (q.get(i) == 'ㄱ' || q.get(i) == 'ㄴ' || q.get(i) == 'ㄷ' || q.get(i) == 'ㄹ' ||q.get(i) == 'ㅁ' ||q.get(i) == 'ㅂ' ||q.get(i) == 'ㅅ' ||q.get(i) == 'ㅇ' ||q.get(i) == 'ㅈ' ||q.get(i) == 'ㅊ' ||q.get(i) == 'ㅋ' ||q.get(i) == 'ㅌ' ||q.get(i) == 'ㅍ' ||q.get(i) == 'ㅎ')&&(q.get(i+1) == 'ㅏ'||q.get(i+1) == 'ㅐ'||q.get(i+1) == 'ㅑ'||q.get(i+1) == 'ㅒ'||q.get(i+1) == 'ㅓ'||q.get(i+1) == 'ㅔ'||q.get(i+1) == 'ㅕ'||q.get(i+1) == 'ㅖ'||    q.get(i+1) == 'ㅗ'||q.get(i+1) == 'ㅚ'||q.get(i+1) == 'ㅛ'||q.get(i+1) == 'ㅜ'||q.get(i+1) == 'ㅟ'||q.get(i+1) == 'ㅠ'||q.get(i+1) == 'ㅡ'||q.get(i+1) == 'ㅢ'||q.get(i+1) == 'ㅣ')&&(q.get(i+2) == 'ㄱ' || q.get(i+2) == 'ㄴ' || q.get(i+2) == 'ㄷ' || q.get(i+2) == 'ㄹ' ||q.get(i+2) == 'ㅁ' ||q.get(i+2) == 'ㅂ' ||q.get(i+2) == 'ㅅ' ||q.get(i+2) == 'ㅇ' ||q.get(i+2) == 'ㅈ' ||q.get(i+2) == 'ㅊ' ||q.get(i+2) == 'ㅋ' ||q.get(i+2) == 'ㅌ' ||q.get(i+2) == 'ㅍ' ||q.get(i+2) == 'ㅎ')
                                switch(q.get(i))
                                    case 'ㄱ'
                                        temp2 = temp2 + (cho1(1)*588);
                                    case 'ㄴ'
                                        temp2 = temp2 + (cho1(3)*588);
                                    case 'ㄷ'
                                        temp2 = temp2 + (cho1(4)*588);
                                    case 'ㄹ'
                                        temp2 = temp2 + (cho1(6)*588);
                                    case 'ㅁ'
                                        temp2 = temp2 + (cho1(7)*588);
                                    case 'ㅂ'
                                        temp2 = temp2 + (cho1(8)*588);
                                    case 'ㅅ'
                                        temp2 = temp2 + (cho1(10)*588);
                                    case 'ㅇ'
                                        temp2 = temp2 + (cho1(12)*588);
                                    case 'ㅈ'
                                        temp2 = temp2 + (cho1(13)*588);
                                    case 'ㅊ'
                                        temp2 = temp2 + (cho1(15)*588);
                                    case 'ㅋ'
                                        temp2 = temp2 + (cho1(16)*588);
                                    case 'ㅌ'
                                        temp2 = temp2 + (cho1(17)*588);
                                    case 'ㅍ'
                                        temp2 = temp2 + (cho1(18)*588);
                                    case 'ㅎ'
                                        temp2 = temp2 + (cho1(19)*588);
                                end
                            elseif (q.get(i) == 'ㄱ' || q.get(i) == 'ㄴ' || q.get(i) == 'ㄷ' || q.get(i) == 'ㄹ' ||q.get(i) == 'ㅁ' ||q.get(i) == 'ㅂ' ||q.get(i) == 'ㅅ' ||q.get(i) == 'ㅇ' ||q.get(i) == 'ㅈ' ||q.get(i) == 'ㅊ' ||q.get(i) == 'ㅋ' ||q.get(i) == 'ㅌ' ||q.get(i) == 'ㅍ' ||q.get(i) == 'ㅎ')&&(q.get(i+1)=='ㅗ'||q.get(i+1)=='ㅜ')&&(q.get(i+2)=='ㅏ'||q.get(i+2)=='ㅐ'||q.get(i+2)=='ㅣ'||q.get(i+2)=='ㅓ'||q.get(i+2)=='ㅔ')
                                switch(q.get(i))
                                    case 'ㄱ'
                                        temp2 = temp2 + (cho1(1)*588);
                                    case 'ㄴ'
                                        temp2 = temp2 + (cho1(3)*588);
                                    case 'ㄷ'
                                        temp2 = temp2 + (cho1(4)*588);
                                    case 'ㄹ'
                                        temp2 = temp2 + (cho1(6)*588);
                                    case 'ㅁ'
                                        temp2 = temp2 + (cho1(7)*588);
                                    case 'ㅂ'
                                        temp2 = temp2 + (cho1(8)*588);
                                    case 'ㅅ'
                                        temp2 = temp2 + (cho1(10)*588);
                                    case 'ㅇ'
                                        temp2 = temp2 + (cho1(12)*588);
                                    case 'ㅈ'
                                        temp2 = temp2 + (cho1(13)*588);
                                    case 'ㅊ'
                                        temp2 = temp2 + (cho1(15)*588);
                                    case 'ㅋ'
                                        temp2 = temp2 + (cho1(16)*588);
                                    case 'ㅌ'
                                        temp2 = temp2 + (cho1(17)*588);
                                    case 'ㅍ'
                                        temp2 = temp2 + (cho1(18)*588);
                                    case 'ㅎ'
                                        temp2 = temp2 + (cho1(19)*588);
                                end
                            elseif (q.get(i) == 'ㅗ'||q.get(i) == 'ㅜ')&&(q.get(i+1)=='ㅏ'||q.get(i+1)=='ㅐ'||q.get(i+1)=='ㅣ'||q.get(i+1)=='ㅓ'||q.get(i+1)=='ㅔ')&&(q.get(i+2) == 'ㄱ' || q.get(i+2) == 'ㄴ' || q.get(i+2) == 'ㄷ' || q.get(i+2) == 'ㄹ' ||q.get(i+2) == 'ㅁ' ||q.get(i+2) == 'ㅂ' ||q.get(i+2) == 'ㅅ' ||q.get(i+2) == 'ㅇ' ||q.get(i+2) == 'ㅈ' ||q.get(i+2) == 'ㅊ' ||q.get(i+2) == 'ㅋ' ||q.get(i+2) == 'ㅌ' ||q.get(i+2) == 'ㅍ' ||q.get(i+2) == 'ㅎ')
                                if q.get(i) =='ㅗ'
                                    switch(q.get(i+1))
                                        case 'ㅏ'
                                            temp2 = temp2 + (jung1(10)*28);
                                        case 'ㅐ'
                                            temp2 = temp2 + (jung1(11)*28);
                                        case 'ㅣ'
                                            temp2 = temp2 + (jung1(12)*28);
                                    end
                                    
                                elseif q.get(i) =='ㅜ'
                                    switch(q.get(i+1))
                                        case 'ㅓ'
                                            temp2 = temp2 + (jung1(15)*28);
                                        case 'ㅔ'
                                            temp2 = temp2 + (jung1(16)*28);
                                        case 'ㅣ'
                                            temp2 = temp2 + (jung1(17)*28);
                                    end
                                end
                                q.remove();
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == 'ㅗ'||q.get(i) == 'ㅜ')&&(q.get(i+1)=='ㅏ'||q.get(i+1)=='ㅐ'||q.get(i+1)=='ㅣ'||q.get(i+1)=='ㅓ'||q.get(i+1)=='ㅔ'||q.get(i+1)=='ㅣ')&&q.get(i+2)=='!'
                                if q.get(i) =='ㅗ'
                                    switch(q.get(i+1))
                                        case 'ㅏ'
                                            temp2 = temp2 + (jung1(10)*28);
                                        case 'ㅐ'
                                            temp2 = temp2 + (jung1(11)*28);
                                        case 'ㅣ'
                                            temp2 = temp2 + (jung1(12)*28);
                                    end
                                    
                                elseif q.get(i) =='ㅜ'
                                    switch(q.get(i+1))
                                        case 'ㅓ'
                                            temp2 = temp2 + (jung1(15)*28);
                                        case 'ㅔ'
                                            temp2 = temp2 + (jung1(16)*28);
                                        case 'ㅣ'
                                            temp2 = temp2 + (jung1(17)*28);
                                    end
                                end
                                q.remove();
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == 'ㅏ'||q.get(i) == 'ㅐ'||q.get(i) == 'ㅑ'||q.get(i) == 'ㅒ'||q.get(i) == 'ㅓ'||q.get(i) == 'ㅔ'||q.get(i) == 'ㅕ'||q.get(i) == 'ㅖ'||    q.get(i) == 'ㅗ'||q.get(i) == 'ㅚ'||q.get(i) == 'ㅛ'||q.get(i) == 'ㅜ'||q.get(i) == 'ㅟ'||q.get(i) == 'ㅠ'||q.get(i) == 'ㅡ'||q.get(i) == 'ㅢ'||q.get(i) == 'ㅣ')&&(q.get(i+1) == 'ㄱ' || q.get(i+1) == 'ㄴ' || q.get(i+1) == 'ㄷ' || q.get(i+1) == 'ㄹ' ||q.get(i+1) == 'ㅁ' ||q.get(i+1) == 'ㅂ' ||q.get(i+1) == 'ㅅ' ||q.get(i+1) == 'ㅇ' ||q.get(i+1) == 'ㅈ' ||q.get(i+1) == 'ㅊ' ||q.get(i+1) == 'ㅋ' ||q.get(i+1) == 'ㅌ' ||q.get(i+1) == 'ㅍ' ||q.get(i+1) == 'ㅎ')&&(q.get(i+2) == 'ㄱ' || q.get(i+2) == 'ㄴ' || q.get(i+2) == 'ㄷ' || q.get(i+2) == 'ㄹ' ||q.get(i+2) == 'ㅁ' ||q.get(i+2) == 'ㅂ' ||q.get(i+2) == 'ㅅ' ||q.get(i+2) == 'ㅇ' ||q.get(i+2) == 'ㅈ' ||q.get(i+2) == 'ㅊ' ||q.get(i+2) == 'ㅋ' ||q.get(i+2) == 'ㅌ' ||q.get(i+2) == 'ㅍ' ||q.get(i+2) == 'ㅎ')
                                switch(q.get(i))
                                    case  'ㅏ'
                                        temp2 = temp2 + (jung1(1)*28);
                                    case  'ㅐ'
                                        temp2 = temp2 + (jung1(2)*28);
                                    case  'ㅑ'
                                        temp2 = temp2 + (jung1(3)*28);
                                    case  'ㅒ'
                                        temp2 = temp2 + (jung1(4)*28);
                                    case  'ㅓ'
                                        temp2 = temp2 + (jung1(5)*28);
                                    case  'ㅔ'
                                        temp2 = temp2 + (jung1(6)*28);
                                    case  'ㅕ'
                                        temp2 = temp2 + (jung1(7)*28);
                                    case  'ㅖ'
                                        temp2 = temp2 + (jung1(8)*28);
                                    case  'ㅗ'
                                        temp2 = temp2 + (jung1(9)*28);
                                    case  'ㅚ'
                                        temp2 = temp2 + (jung1(12)*28);
                                    case  'ㅛ'
                                        temp2 = temp2 + (jung1(13)*28);
                                    case  'ㅜ'
                                        temp2 = temp2 + (jung1(14)*28);
                                    case  'ㅟ'
                                        temp2 = temp2 + (jung1(17)*28);
                                    case  'ㅠ'
                                        temp2 = temp2 + (jung1(18)*28);
                                    case  'ㅡ'
                                        temp2 = temp2 + (jung1(19)*28);
                                    case  'ㅢ'
                                        temp2 = temp2 + (jung1(20)*28);
                                    case  'ㅣ'
                                        temp2 = temp2 + (jung1(21)*28);
                                end
                            elseif (q.get(i) == 'ㅏ'||q.get(i) == 'ㅐ'||q.get(i) == 'ㅑ'||q.get(i) == 'ㅒ'||q.get(i) == 'ㅓ'||q.get(i) == 'ㅔ'||q.get(i) == 'ㅕ'||q.get(i) == 'ㅖ'||    q.get(i) == 'ㅗ'||q.get(i) == 'ㅚ'||q.get(i) == 'ㅛ'||q.get(i) == 'ㅜ'||q.get(i) == 'ㅟ'||q.get(i) == 'ㅠ'||q.get(i) == 'ㅡ'||q.get(i) == 'ㅢ'||q.get(i) == 'ㅣ')&&(q.get(i+1) == 'ㄱ' || q.get(i+1) == 'ㄴ' || q.get(i+1) == 'ㄷ' || q.get(i+1) == 'ㄹ' ||q.get(i+1) == 'ㅁ' ||q.get(i+1) == 'ㅂ' ||q.get(i+1) == 'ㅅ' ||q.get(i+1) == 'ㅇ' ||q.get(i+1) == 'ㅈ' ||q.get(i+1) == 'ㅊ' ||q.get(i+1) == 'ㅋ' ||q.get(i+1) == 'ㅌ' ||q.get(i+1) == 'ㅍ' ||q.get(i+1) == 'ㅎ')&&(q.get(i+2) == 'ㅏ'||q.get(i+2) == 'ㅐ'||q.get(i+2) == 'ㅑ'||q.get(i+2) == 'ㅒ'||q.get(i+2) == 'ㅓ'||q.get(i+2) == 'ㅔ'||q.get(i+2) == 'ㅕ'||q.get(i+2) == 'ㅖ'||    q.get(i+2) == 'ㅗ'||q.get(i+2) == 'ㅚ'||q.get(i+2) == 'ㅛ'||q.get(i+2) == 'ㅜ'||q.get(i+2) == 'ㅟ'||q.get(i+2) == 'ㅠ'||q.get(i+2) == 'ㅡ'||q.get(i+2) == 'ㅢ'||q.get(i+2) == 'ㅣ')
                                switch(q.get(i))
                                    case  'ㅏ'
                                        temp2 = temp2 + (jung1(1)*28);
                                    case  'ㅐ'
                                        temp2 = temp2 + (jung1(2)*28);
                                    case  'ㅑ'
                                        temp2 = temp2 + (jung1(3)*28);
                                    case  'ㅒ'
                                        temp2 = temp2 + (jung1(4)*28);
                                    case  'ㅓ'
                                        temp2 = temp2 + (jung1(5)*28);
                                    case  'ㅔ'
                                        temp2 = temp2 + (jung1(6)*28);
                                    case  'ㅕ'
                                        temp2 = temp2 + (jung1(7)*28);
                                    case  'ㅖ'
                                        temp2 = temp2 + (jung1(8)*28);
                                    case  'ㅗ'
                                        temp2 = temp2 + (jung1(9)*28);
                                    case  'ㅚ'
                                        temp2 = temp2 + (jung1(12)*28);
                                    case  'ㅛ'
                                        temp2 = temp2 + (jung1(13)*28);
                                    case  'ㅜ'
                                        temp2 = temp2 + (jung1(14)*28);
                                    case  'ㅟ'
                                        temp2 = temp2 + (jung1(17)*28);
                                    case  'ㅠ'
                                        temp2 = temp2 + (jung1(18)*28);
                                    case  'ㅡ'
                                        temp2 = temp2 + (jung1(19)*28);
                                    case  'ㅢ'
                                        temp2 = temp2 + (jung1(20)*28);
                                    case  'ㅣ'
                                        temp2 = temp2 + (jung1(21)*28);
                                end
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == 'ㄱ' || q.get(i) == 'ㄴ' || q.get(i) == 'ㄷ' || q.get(i) == 'ㄹ' ||q.get(i) == 'ㅁ' ||q.get(i) == 'ㅂ' ||q.get(i) == 'ㅅ' ||q.get(i) == 'ㅇ' ||q.get(i) == 'ㅈ' ||q.get(i) == 'ㅊ' ||q.get(i) == 'ㅋ' ||q.get(i) == 'ㅌ' ||q.get(i) == 'ㅍ' ||q.get(i) == 'ㅎ')&&(q.get(i+1) == 'ㄱ' || q.get(i+1) == 'ㄴ' || q.get(i+1) == 'ㄷ' || q.get(i+1) == 'ㄹ' ||q.get(i+1) == 'ㅁ' ||q.get(i+1) == 'ㅂ' ||q.get(i+1) == 'ㅅ' ||q.get(i+1) == 'ㅇ' ||q.get(i+1) == 'ㅈ' ||q.get(i+1) == 'ㅊ' ||q.get(i+1) == 'ㅋ' ||q.get(i+1) == 'ㅌ' ||q.get(i+1) == 'ㅍ' ||q.get(i+1) == 'ㅎ')&&(q.get(i+2) == 'ㅏ'||q.get(i+2) == 'ㅐ'||q.get(i+2) == 'ㅑ'||q.get(i+2) == 'ㅒ'||q.get(i+2) == 'ㅓ'||q.get(i+2) == 'ㅔ'||q.get(i+2) == 'ㅕ'||q.get(i+2) == 'ㅖ'||    q.get(i+2) == 'ㅗ'||q.get(i+2) == 'ㅚ'||q.get(i+2) == 'ㅛ'||q.get(i+2) == 'ㅜ'||q.get(i+2) == 'ㅟ'||q.get(i+2) == 'ㅠ'||q.get(i+2) == 'ㅡ'||q.get(i+2) == 'ㅢ'||q.get(i+2) == 'ㅣ')
                                switch(q.get(i))
                                    case  'ㄱ'
                                        temp2 = temp2 + jong1(2);
                                    case  'ㄴ'
                                        temp2 = temp2 + jong1(5);
                                    case  'ㄷ'
                                        temp2 = temp2 + jong1(8);
                                    case  'ㄹ'
                                        temp2 = temp2 + jong1(9);
                                    case  'ㅁ'
                                        temp2 = temp2 + jong1(17);
                                    case  'ㅂ'
                                        temp2 = temp2 + jong1(18);
                                    case  'ㅅ'
                                        temp2 = temp2 + jong1(20);
                                    case  'ㅇ'
                                        temp2 = temp2 + jong1(22);
                                    case  'ㅈ'
                                        temp2 = temp2 + jong1(23);
                                    case  'ㅊ'
                                        temp2 = temp2 + jong1(24);
                                    case  'ㅋ'
                                        temp2 = temp2 + jong1(25);
                                    case  'ㅌ'
                                        temp2 = temp2 + jong1(26);
                                    case  'ㅍ'
                                        temp2 = temp2 + jong1(27);
                                    case  'ㅎ'
                                        temp2 = temp2 + jong1(28);
                                end
                                q.remove();
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == 'ㄱ' || q.get(i) == 'ㄴ' || q.get(i) == 'ㄷ' || q.get(i) == 'ㄹ' ||q.get(i) == 'ㅁ' ||q.get(i) == 'ㅂ' ||q.get(i) == 'ㅅ' ||q.get(i) == 'ㅇ' ||q.get(i) == 'ㅈ' ||q.get(i) == 'ㅊ' ||q.get(i) == 'ㅋ' ||q.get(i) == 'ㅌ' ||q.get(i) == 'ㅍ' ||q.get(i) == 'ㅎ')&&q.get(i+1)=='!'&&q.get(i+2)=='@'
                                switch(q.get(i))
                                    case  'ㄱ'
                                        temp2 = temp2 + jong1(2);
                                    case  'ㄴ'
                                        temp2 = temp2 + jong1(5);
                                    case  'ㄷ'
                                        temp2 = temp2 + jong1(8);
                                    case  'ㄹ'
                                        temp2 = temp2 + jong1(9);
                                    case  'ㅁ'
                                        temp2 = temp2 + jong1(17);
                                    case  'ㅂ'
                                        temp2 = temp2 + jong1(18);
                                    case  'ㅅ'
                                        temp2 = temp2 + jong1(20);
                                    case  'ㅇ'
                                        temp2 = temp2 + jong1(22);
                                    case  'ㅈ'
                                        temp2 = temp2 + jong1(23);
                                    case  'ㅊ'
                                        temp2 = temp2 + jong1(24);
                                    case  'ㅋ'
                                        temp2 = temp2 + jong1(25);
                                    case  'ㅌ'
                                        temp2 = temp2 + jong1(26);
                                    case  'ㅍ'
                                        temp2 = temp2 + jong1(27);
                                    case  'ㅎ'
                                        temp2 = temp2 + jong1(28);
                                end
                                q.remove();
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == 'ㄱ' || q.get(i) == 'ㄴ' || q.get(i) == 'ㄷ' || q.get(i) == 'ㄹ' ||q.get(i) == 'ㅁ' ||q.get(i) == 'ㅂ' ||q.get(i) == 'ㅅ' ||q.get(i) == 'ㅇ' ||q.get(i) == 'ㅈ' ||q.get(i) == 'ㅊ' ||q.get(i) == 'ㅋ' ||q.get(i) == 'ㅌ' ||q.get(i) == 'ㅍ' ||q.get(i) == 'ㅎ')&&(q.get(i+1) == 'ㅏ'||q.get(i+1) == 'ㅐ'||q.get(i+1) == 'ㅑ'||q.get(i+1) == 'ㅒ'||q.get(i+1) == 'ㅓ'||q.get(i+1) == 'ㅔ'||q.get(i+1) == 'ㅕ'||q.get(i+1) == 'ㅖ'||    q.get(i+1) == 'ㅗ'||q.get(i+1) == 'ㅚ'||q.get(i+1) == 'ㅛ'||q.get(i+1) == 'ㅜ'||q.get(i+1) == 'ㅟ'||q.get(i+1) == 'ㅠ'||q.get(i+1) == 'ㅡ'||q.get(i+1) == 'ㅢ'||q.get(i+1) == 'ㅣ')&&q.get(i+2)=='!'
                                switch(q.get(i))
                                    case 'ㄱ'
                                        temp2 = temp2 + (cho1(1)*588);
                                    case 'ㄴ'
                                        temp2 = temp2 + (cho1(3)*588);
                                    case 'ㄷ'
                                        temp2 = temp2 + (cho1(4)*588);
                                    case 'ㄹ'
                                        temp2 = temp2 + (cho1(6)*588);
                                    case 'ㅁ'
                                        temp2 = temp2 + (cho1(7)*588);
                                    case 'ㅂ'
                                        temp2 = temp2 + (cho1(8)*588);
                                    case 'ㅅ'
                                        temp2 = temp2 + (cho1(10)*588);
                                    case 'ㅇ'
                                        temp2 = temp2 + (cho1(12)*588);
                                    case 'ㅈ'
                                        temp2 = temp2 + (cho1(13)*588);
                                    case 'ㅊ'
                                        temp2 = temp2 + (cho1(15)*588);
                                    case 'ㅋ'
                                        temp2 = temp2 + (cho1(16)*588);
                                    case 'ㅌ'
                                        temp2 = temp2 + (cho1(17)*588);
                                    case 'ㅍ'
                                        temp2 = temp2 + (cho1(18)*588);
                                    case 'ㅎ'
                                        temp2 = temp2 + (cho1(19)*588);
                                end
                            elseif (q.get(i) == 'ㅏ'||q.get(i) == 'ㅐ'||q.get(i) == 'ㅑ'||q.get(i) == 'ㅒ'||q.get(i) == 'ㅓ'||q.get(i) == 'ㅔ'||q.get(i) == 'ㅕ'||q.get(i) == 'ㅖ'||    q.get(i) == 'ㅗ'||q.get(i) == 'ㅚ'||q.get(i) == 'ㅛ'||q.get(i) == 'ㅜ'||q.get(i) == 'ㅟ'||q.get(i) == 'ㅠ'||q.get(i) == 'ㅡ'||q.get(i) == 'ㅢ'||q.get(i) == 'ㅣ')&&(q.get(i+1) == 'ㄱ' || q.get(i+1) == 'ㄴ' || q.get(i+1) == 'ㄷ' || q.get(i+1) == 'ㄹ' ||q.get(i+1) == 'ㅁ' ||q.get(i+1) == 'ㅂ' ||q.get(i+1) == 'ㅅ' ||q.get(i+1) == 'ㅇ' ||q.get(i+1) == 'ㅈ' ||q.get(i+1) == 'ㅊ' ||q.get(i+1) == 'ㅋ' ||q.get(i+1) == 'ㅌ' ||q.get(i+1) == 'ㅍ' ||q.get(i+1) == 'ㅎ')&&q.get(i+2)=='!'
                                switch(q.get(i))
                                    case  'ㅏ'
                                        temp2 = temp2 + (jung1(1)*28);
                                    case  'ㅐ'
                                        temp2 = temp2 + (jung1(2)*28);
                                    case  'ㅑ'
                                        temp2 = temp2 + (jung1(3)*28);
                                    case  'ㅒ'
                                        temp2 = temp2 + (jung1(4)*28);
                                    case  'ㅓ'
                                        temp2 = temp2 + (jung1(5)*28);
                                    case  'ㅔ'
                                        temp2 = temp2 + (jung1(6)*28);
                                    case  'ㅕ'
                                        temp2 = temp2 + (jung1(7)*28);
                                    case  'ㅖ'
                                        temp2 = temp2 + (jung1(8)*28);
                                    case  'ㅗ'
                                        temp2 = temp2 + (jung1(9)*28);
                                    case  'ㅚ'
                                        temp2 = temp2 + (jung1(12)*28);
                                    case  'ㅛ'
                                        temp2 = temp2 + (jung1(13)*28);
                                    case  'ㅜ'
                                        temp2 = temp2 + (jung1(14)*28);
                                    case  'ㅟ'
                                        temp2 = temp2 + (jung1(17)*28);
                                    case  'ㅠ'
                                        temp2 = temp2 + (jung1(18)*28);
                                    case  'ㅡ'
                                        temp2 = temp2 + (jung1(19)*28);
                                    case  'ㅢ'
                                        temp2 = temp2 + (jung1(20)*28);
                                    case  'ㅣ'
                                        temp2 = temp2 + (jung1(21)*28);
                                end
                            elseif (q.get(i) == 'ㅏ'||q.get(i) == 'ㅐ'||q.get(i) == 'ㅑ'||q.get(i) == 'ㅒ'||q.get(i) == 'ㅓ'||q.get(i) == 'ㅔ'||q.get(i) == 'ㅕ'||q.get(i) == 'ㅖ'||    q.get(i) == 'ㅗ'||q.get(i) == 'ㅚ'||q.get(i) == 'ㅛ'||q.get(i) == 'ㅜ'||q.get(i) == 'ㅟ'||q.get(i) == 'ㅠ'||q.get(i) == 'ㅡ'||q.get(i) == 'ㅢ'||q.get(i) == 'ㅣ')&&q.get(i+1)=='!'&&q.get(i+2)=='@'
                                switch(q.get(i))
                                    case  'ㅏ'
                                        temp2 = temp2 + (jung1(1)*28);
                                    case  'ㅐ'
                                        temp2 = temp2 + (jung1(2)*28);
                                    case  'ㅑ'
                                        temp2 = temp2 + (jung1(3)*28);
                                    case  'ㅒ'
                                        temp2 = temp2 + (jung1(4)*28);
                                    case  'ㅓ'
                                        temp2 = temp2 + (jung1(5)*28);
                                    case  'ㅔ'
                                        temp2 = temp2 + (jung1(6)*28);
                                    case  'ㅕ'
                                        temp2 = temp2 + (jung1(7)*28);
                                    case  'ㅖ'
                                        temp2 = temp2 + (jung1(8)*28);
                                    case  'ㅗ'
                                        temp2 = temp2 + (jung1(9)*28);
                                    case  'ㅚ'
                                        temp2 = temp2 + (jung1(12)*28);
                                    case  'ㅛ'
                                        temp2 = temp2 + (jung1(13)*28);
                                    case  'ㅜ'
                                        temp2 = temp2 + (jung1(14)*28);
                                    case  'ㅟ'
                                        temp2 = temp2 + (jung1(17)*28);
                                    case  'ㅠ'
                                        temp2 = temp2 + (jung1(18)*28);
                                    case  'ㅡ'
                                        temp2 = temp2 + (jung1(19)*28);
                                    case  'ㅢ'
                                        temp2 = temp2 + (jung1(20)*28);
                                    case  'ㅣ'
                                        temp2 = temp2 + (jung1(21)*28);
                                end
                                q.remove();
                                q.remove();
                                break;
                            end
                            
                        end
                        temp1(j) = temp1(j) + temp2;
                        temp2 = 0;
                    end
                    
                    [m,n] = size(temp1);
                    for h=1:n
                        temp1(h) = temp1(h)+44032;
                    end
                    %저장된 데이터 출력및 tts 출력 
                    set(b,'String', char(temp1),'position',[80 130 650 120])
                    tts(char(temp1))
                    %저장된 큐 삭제 
                    for m=0:q.size()-1
                        q.remove();
                    end
                    %전역변수 초기화
                    temp1 = [];
                    %번역 멈춤
                    stop(depthVid);
                    stop(colorVid);
                    stop(t);
                end
                %정확도 증가를 위해 5개의 값이 같으면 q에 저장
                if countT == 5
                    if accuracyR(1) == accuracyR(2) && accuracyR(2) == accuracyR(3) && accuracyR(3) == accuracyR(4) && accuracyR(4) == accuracyR(5)
                        set(d,'String', char(accuracyR(2)),'position',[420 440 320 120])
                         % tts 결과 출력 및 q에 저장
                        tts(char(accuracyR(2)))
                        q.add(char(accuracyR(1)));
                    end
                    countT = 0;
                end
                countT = countT + 1;
            end
        end
        
        
    end

% 궤적 함수 선언
    function dispDepth2(obj, event)
        
        % 영상 출력
        trigger(depthVid);
        trigger(colorVid);
        [depthMap, ~, depthMetaData] = getdata(depthVid);
        [colorFrameData] = getdata(colorVid);
        idx = find(depthMetaData.IsSkeletonTracked);
        ax = subplot(2,2,1);
        set(ax, 'position', [0.09,0.43 0.41 0.55]);
        imshow(colorFrameData);
        
        % 영상처리
        % 스켈레톤 추적이 됐을 때
        if idx ~= 0
            
            % 척추 위치 기반 상반신 추적
            body = depthMetaData.JointDepthIndices(3,:,idx);
            
            % 사각형으로 상반신 크롭
            radius = 300;
            bodyBox = [body(1)-0.75*radius body(2)-0.3*radius 1.5*radius radius];
            rectangle('position', bodyBox, 'EdgeColor', [1 1 0]);
            bodyImage = imcrop(colorFrameData,bodyBox);
            
            % 크롭이 됐을 때
            if ~isempty(bodyImage)
                
                % timer 함수가 불릴 때마다 m증가
                m=m+1;
                
                % 이미지 리사이징 후 저장
                k(:,:,:,m)= uint8(imresize(bodyImage,[300,450]));
                
                % 10프레임으로 3초 이후
                if(m==30)
                    
                    % 저장한 이미지를 비디오로 저장
                    video = centerCrop(k,inputSize);
                    
                    % 비디오를 구글넷에 알맞은 데이터로 변환
                    sequences{1}= activations(netCNN,video,layerName,'OutputAs','columns');
                    
                    % 구글넷을 활용한 결과 예측
                    YPred = classify(netLSTM,sequences);
                    result = string(YPred);
                    
                   
                    % tts로 결과 출력
                    set(d,'String', result,'position',[420 440 320 120])
                    tts(result)
                    q.add(char(result));
                    m=0;
                    
                end
            else
                m=0;
            end
        end
    end

% 각 기능에 대한 callback 함수 선언
    function startCallback2(obj, event)
        start(depthVid);
        start(colorVid);
        start(t2);
    end

    function startCallback(obj, event)
        start(depthVid);
        start(colorVid);
        start(t);
    end
    
    function stopCallback(obj, event)
         %스탑 누르면 저장된 데이터 문장으로 연결
                        if q.size()-1 == 2
                            for y=0:q.size()-1
                                if y==0
                                    temp3(y+1) = char(q.get(y)+"는");
                                elseif y==1
                                    temp3(y+1) = char(q.get(y)+"를"+" ");
                                elseif y==2
                                    temp3(y+1) = char(q.get(y)+" ");
                                end
                            end
                        else
                            for y=0:q.size()-1
                                temp3(y+1) = char(q.get(y)+" ");
                            end
                        end
                        %q데이터 삭제
                        for m=0:q.size()-1
                            q.remove();
                        end
                        
                        newstr = join(temp3);
                        %문장 출력
                        set(b,'String', char(temp3),'position',[80 130 650 120])
                        tts(char(newstr))
                        %전역변수 초기화
                        temp3 = [""];
                        newstr = "";
                        %번역 멈춤
                        stop(depthVid);
                        stop(colorVid);
                        stop(t2);
    end

    function speechCallback(obj, event)
        start(t3);
        stop(t3);
    end
end

% 비디오 리사이징 함수 선언
function videoResized = centerCrop(video,inputSize)

% 비디오 사이즈 저장
sz = size(video);

% 비디오가 풍경일 때
if sz(1) < sz(2)
    idx = floor((sz(2) - sz(1))/2);
    video(:,1:(idx-1),:,:) = [];
    video(:,(sz(1)+1):end,:,:) = [];
    
    % 비디오에 인물이 있을 때
elseif sz(2) < sz(1)
    
    idx = floor((sz(1) - sz(2))/2);
    video(1:(idx-1),:,:,:) = [];
    video((sz(2)+1):end,:,:,:) = [];
end

% 비디오 사이즈 변환
videoResized = imresize(video,inputSize(1:2));

end
