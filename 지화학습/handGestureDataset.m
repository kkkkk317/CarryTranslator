% handGestureDataset.m
% GUI 기반 지화 이미지 저장 프로그램
function handGestureDataset()

% 키넥트 초기화
% 스켈레톤 인식을 위한 depth 캠
depthVid = videoinput('kinect', 2);
triggerconfig(depthVid, 'manual');
depthVid.FramesPerTrigger = 1;
depthVid.TriggerRepeat = inf;
set(getselectedsource(depthVid), 'TrackingMode', 'Skeleton');

% color 캠 초기화
colorVid = videoinput('kinect', 1);
triggerconfig(colorVid, 'manual');
colorVid.FramesPerTrigger = 1;
colorVid.TriggerRepeat = inf;

% 함수를 위한 타이머 설정
t = timer('TimerFcn', @dispDepth, 'Period', 0.05, ...
    'executionMode', 'fixedRate');

% GUI 프레임워크 설정
window=figure('Color',[0 0 0],'Name','Depth Camera',...
    'DockControl','off','Units','Pixels',...
    'toolbar','none',...
    'Position',[50 50 800 600]);

% 지화 이미지 저장을 시작하기 위한 버튼 설정
startb=uicontrol('Parent',window,'Style','pushbutton','String',...
    'START',...
    'FontSize',15 ,...
    'Units','normalized',...
    'Position',[0.22 0.02 0.16 0.08],...
    'Callback',@startCallback);
startb.BackgroundColor = '#ff8c00';
startb.ForegroundColor = 'white';

% 지화 이미지 저장을 멈추기 위한 버튼 설정
stopb=uicontrol('Parent',window,'Style','pushbutton','String',...
    'STOP',...
    'FontSize',15 ,...
    'Units','normalized',...
    'Position',[0.5 0.02 0.16 0.08],...
    'Callback',@stopCallback);

% 변수 초기화
i = 0;
m = 0;

% 깊이를 보여주기 위한 함수 선언
    function dispDepth(obj, event)
        
        % 영상 출력(0~4096 로 프레임 재지정)
        trigger(colorVid);
        trigger(depthVid);
        [depthMap, ~, depthMetaData] = getdata(depthVid);
        [colorMap, ~, colorMetaData] = getdata(colorVid);
        idx = find(depthMetaData.IsSkeletonTracked);
        subplot(2,2,1);
        imshow(depthMap, [0 4096]);
        
        % 영상 처리
        % 스켈레톤 추적이 됐을 때
        if idx ~= 0
            
            % 오른손 위치 추적
            rightHand = depthMetaData.JointDepthIndices(12,:,idx);
            
            % 오른손 데이터값 추출
            zCoord = 1e3*min(depthMetaData.JointWorldCoordinates(12,:,idx));
            radius = round(90 - zCoord / 50);
            rightHandBox = [rightHand-0.5*radius 1.2*radius 1.2*radius];
            
            % 사각형으로 오른손 크롭 후 화면에 표시
            rectangle('position', rightHandBox, 'EdgeColor', [1 1 0]);
            handColorImage = imcrop(colorMap,rightHandBox);
            result = rgb2gray(handColorImage);
            subplot(2,2,3);
            imshow(handColorImage, [0 4096]);
            
            % 데이터 추출이 됐을 때
            if ~isempty(handColorImage)
                
                % 배경 전처리
                imageSize = size(handColorImage);
                
                for k = 1:imageSize(1)
                    for j = 1:imageSize(2)
                        if handColorImage(k, j) > 2300
                            handColorImage(k, j) = 0;
                        end
                    end
                end
                
                % 지화 이미지를 폴더에 저장
                i = i+1;
                if (mod(i,5)==1)
                    %원하는 문자를 넣어서 학습
                    imwrite(imresize(handColorImage,[224,224]), strcat('hangeul/ㄱ/ㄱ_',num2str(m),'.png'),'png');
                    m=m+1;
                end
            end
        end
    end

% 각 기능에 대한 callback 함수 선언
    function startCallback(obj, event)
        start(colorVid);
        start(depthVid);
        start(t);
    end

    function stopCallback(obj, event)
        stop(t);
        stop(colorVid);
        stop(depthVid);
        m=0;
    end
end
