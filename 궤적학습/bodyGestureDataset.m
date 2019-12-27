% bodyGestureDataset.m
% GUI 기반 궤적 영상 저장 프로그램
function bodyGestureDataset()

% 전역 변수 선언
clear x;
global x;

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
t = timer('TimerFcn', @dispDepth, 'Period', 0.1, ...
    'executionMode', 'fixedRate');

% GUI 프레임워크 설정
window=figure('Color',[0 0 0],'Name','Depth Camera',...
    'DockControl','off','Units','Pixels',...
    'toolbar','none',...
    'Position',[50 50 800 600]);

% 궤적 영상 저장을 시작하기 위한 버튼 설정
startb=uicontrol('Parent',window,'Style','pushbutton','String',...
    'START',...
    'FontSize',15 ,...
    'Units','normalized',...
    'Position',[0.22 0.02 0.16 0.08],...
    'Callback',@startCallback);
startb.BackgroundColor = '#ff8c00';
startb.ForegroundColor = 'white';

% 궤적 영상 저장을 멈추기 위한 버튼 설정
stopb=uicontrol('Parent',window,'Style','pushbutton','String',...
    'STOP',...
    'FontSize',15 ,...
    'Units','normalized',...
    'Position',[0.5 0.02 0.16 0.08],...
    'Callback',@stopCallback);

% 변수 초기화
i = 0;
m=0;

% 깊이를 보여주기 위한 함수 선언
    function dispDepth(obj, event)
        
        % 영상 출력(0~4096 로 프레임 재지정)
        trigger(colorVid);
        trigger(depthVid);
        [depthMap, ~, depthMetaData] = getdata(depthVid);
        [colorMetaData] = getdata(colorVid);
        idx = find(depthMetaData.IsSkeletonTracked);
        subplot(2,2,1);
        imshow(colorMetaData, [0 4096]);
        
        % 영상 처리
        % 스켈레톤 추적이 됐을 때
        if idx ~= 0
            
            % 상체 위치 추적
            body = depthMetaData.JointDepthIndices(3,:,idx);
            
            % 상체 데이터값 추출
            radius = 300;
            bodyBox = [body(1)-0.75*radius body(2)-0.3*radius 1.5*radius radius];
            
            % 사각형으로 상체 크롭 후 화면에 표시
            rectangle('position', bodyBox, 'EdgeColor', [1 1 0]);
            bodyImage = imcrop(colorMetaData,bodyBox);
            
            % 데이터 추출이 됐을 때
            if ~isempty(bodyImage)
                
                m=m+1;
                x(:,:,:,m)= imresize(bodyImage,[300,450]);
                
                % 30 프레임이 되었을 때 궤적 영상을 폴더에 저장
                if(m==30)
                    i = i+1;
                    %원하는 동작을 입력하여 저장
                    outputVideo = VideoWriter(fullfile(strcat('수화영상폴더/예시/예시','_',num2str(i))));
                    outputVideo.FrameRate = 10;
                    open(outputVideo)
                    
                    for ii = 1:30
                        writeVideo(outputVideo,mat2gray(x(:,:,:,ii)));
                    end
                    
                    close(outputVideo)
                    m=0;
                end
            else
                m=0;
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

