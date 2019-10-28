% translator.m
% GUI 기반 수화인식 프로그램
function translator(net, netLSTM)

% 전역 변수 선언
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
window=figure('Color',[0.9255 0.9137 0.8471],'Name','Depth Camera',...
    'DockControl','off','Units','Pixels',...
    'toolbar','none',...
    'Position',[50 50 800 600]);

% 수화 번역 결과창 설정
b = uicontrol('Parent',window,'Style','text');
set(b,'String','수화 번역 결과','position',[150 150 250 80])
b.BackgroundColor = 'black';
b.ForegroundColor = 'white';
b.FontName = 'Dotum';
b.FontSize = 30;

% STT 결과창 설정
c = uicontrol('Parent',window,'Style','text');
set(c,'String','음성 인식 결과','position',[450 150 250 80])
c.BackgroundColor = 'black';
c.ForegroundColor = 'white';
c.FontName = 'Dotum';
c.FontSize = 30;

% 지화를 인식하기 위한 버튼 설정
startb1=uicontrol('Parent',window,'Style','pushbutton','String',...
    '지화',...
    'FontSize',11 ,...
    'Units','normalized',...
    'Position',[0.1 0.02 0.16 0.08],...
    'Callback',@startCallback);

% 궤적을 인식하기 위한 버튼 설정
startb=uicontrol('Parent',window,'Style','pushbutton','String',...
    '궤적',...
    'FontSize',11 ,...
    'Units','normalized',...
    'Position',[0.3 0.02 0.16 0.08],...
    'Callback',@startCallback2);

% 프로그램을 멈추기 위한 버튼 설정
stopb=uicontrol('Parent',window,'Style','pushbutton','String',...
    'STOP',...
    'FontSize',11 ,...
    'Units','normalized',...
    'Position',[0.5 0.02 0.16 0.08],...
    'Callback',@stopCallback);

% 음성 인식을 하기 위한 버튼 설정
speechb=uicontrol('Parent',window,'Style','pushbutton','String',...
    '말하기',...
    'FontSize',11 ,...
    'Units','normalized',...
    'Position',[0.7 0.02 0.16 0.08],...
    'Callback',@speechCallback);

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
        set(c,'String', result,'position',[450 150 250 80])
    end

% 지화 함수
    function dispDepth(obj, event)
        
        % 영상 출력(0~4096 로 프레임 재지정)
        trigger(depthVid);
        trigger(colorVid);
        [depthMap, ~, depthMetaData] = getdata(depthVid);
        [colorFrameData] = getdata(colorVid);
        idx = find(depthMetaData.IsSkeletonTracked);
        subplot(2,2,1);
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
                
                % tts 결과 출력
                set(b,'String', result,'position',[150 150 250 80])
                tts(result)
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
        subplot(2,2,1);
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
                    set(b,'String', result,'position',[150 150 250 80])
                    tts(result)
                    
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
        stop(depthVid);
        stop(colorVid);
        stop(t);
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

