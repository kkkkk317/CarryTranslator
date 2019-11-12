% translator.m
% GUI ��� ��ȭ�ν� ���α׷�
% test


function translator(net, netLSTM)
%������ ������ �ڹ� ���Ḯ��Ʈ ����
import java.util.LinkedList
q = LinkedList();
%�ʼ� �߼� ������ ��
cho1  = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18];
jung1 = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
jong1 = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27];
%���� ���� ����
temp1 = [];
temp2 = 0;
temp3 = [""];
countT = 1;
accuracyR = ["a", "b"];
clear k;
global k;
m = 0;

% googleNet input ����
netCNN = googlenet;
inputSize = netCNN.Layers(1).InputSize(1:2);
layerName = "pool5-7x7_s1";

% Ű��Ʈ �ʱ�ȭ
colorVid = videoinput('kinect', 1);
depthVid = videoinput('kinect', 2);

% ���̷��� �ν��� ���� depth ķ
triggerconfig(depthVid, 'manual');
depthVid.FramesPerTrigger = 1;
depthVid.TriggerRepeat = inf;
set(getselectedsource(depthVid), 'TrackingMode', 'Skeleton');

% color ķ �ʱ�ȭ
triggerconfig(colorVid, 'manual');
colorVid.FramesPerTrigger = 1;
colorVid.TriggerRepeat = inf;

% �Լ��� ���� Ÿ�̸� ����
t2 = timer('Period', 0.1,'ExecutionMode', 'fixedRate');
t2.TimerFcn = @dispDepth2;
t = timer('Period', 0.1,'ExecutionMode', 'fixedRate');
t.TimerFcn = @dispDepth;
t3 = timer('Period', 10,'ExecutionMode', 'fixedRate');
t3.TimerFcn = @speechfc;

% GUI �����ӿ�ũ ����
window=figure('Color',[0, 0, 0],'Name','Depth Camera',...
    'DockControl','off','Units','Pixels',...
    'toolbar','none',...
    'Position',[50 50 800 600]);
padd = uicontrol('Parent',window,'Style','text');
set(padd,'String',' ','position',[70 120 670 140])
padd.BackgroundColor = [1, 0.55 , 0];
% ��ȭ ���� ���â ����
b = uicontrol('Parent',window,'Style','text');
set(b,'String','��ȭ ��ħ ���','position',[80 130 650 120])
b.BackgroundColor = [1, 1 , 1];
b.ForegroundColor = 'black';
b.FontName = 'Dotum';
b.FontSize = 30;
b.FontWeight = 'bold';

d = uicontrol('Parent',window,'Style','text');
set(d,'String','��ȭ,��ȭ ���� ���','position',[420 440 320 120])
d.BackgroundColor = [1, 1 , 1];
d.ForegroundColor = 'black';
d.FontName = 'Dotum';
d.FontSize = 38;
d.FontWeight = 'bold';

% STT ���â ����
c = uicontrol('Parent',window,'Style','text');
set(c,'String','���� �ν� ���','position',[420 290 320 120])
c.BackgroundColor = [1, 1 , 1];
c.ForegroundColor = 'black';
c.FontName = 'Dotum';
c.FontSize = 30;
c.FontWeight = 'bold';

% ��ȭ�� �ν��ϱ� ���� ��ư ����
startb1=uicontrol('Parent',window,'Style','pushbutton','String',...
    '��ȭ',...
    'FontSize',20 ,...
    'Units','normalized',...
    'Position',[0.08 0.04 0.2 0.13],...
    'Callback',@startCallback);
startb1.FontWeight = 'bold';


% ������ �ν��ϱ� ���� ��ư ����
startb=uicontrol('Parent',window,'Style','pushbutton','String',...
    '��ȭ',...
    'FontSize',20 ,...
    'Units','normalized',...
    'Position',[0.295 0.04 0.2 0.13],...
    'Callback',@startCallback2);
startb.FontWeight = 'bold';

% ���α׷��� ���߱� ���� ��ư ����
stopb=uicontrol('Parent',window,'Style','pushbutton','String',...
    'STOP',...
    'FontSize',20 ,...
    'Units','normalized',...
    'Position',[0.51 0.04 0.2 0.13],...
    'Callback',@stopCallback);
stopb.FontWeight = 'bold';

% ���� �ν��� �ϱ� ���� ��ư ����
speechb=uicontrol('Parent',window,'Style','pushbutton','String',...
    '���ϱ�',...
    'FontSize',20 ,...
    'Units','normalized',...
    'Position',[0.725 0.04 0.2 0.13],...
    'Callback',@speechCallback);
speechb.BackgroundColor = '#ff8c00';
speechb.ForegroundColor = 'white';
speechb.FontWeight = 'bold';

% ����ġ �Լ� ����
    function speechfc(obj, event)
        % ���� ����
        recObj = audiorecorder(44100, 16, 1);
        speechObject = speechClient('Google','languageCode','ko-KR');
        disp('Start speaking.')
        recordblocking(recObj, 5);
        disp('End of Recording.')
        
        % ������ ������ ���Ϸ� ������ load
        filename = 'sample.wav';
        y = getaudiodata(recObj);
        audiowrite(filename, y, 48000);
        [samples, fs] = audioread('sample.wav');
        
        % ���� ������ STT�� ������
        outInfo = speech2text(speechObject, samples, fs);
        result = outInfo.Transcript;
        set(c,'String', result,'position',[420 290 320 120])
    end

% ��ȭ �Լ�
    function dispDepth(obj, event)
        
        % ���� ���(0~4096 �� ������ ������)
        trigger(depthVid);
        trigger(colorVid);
        [depthMap, ~, depthMetaData] = getdata(depthVid);
        [colorFrameData] = getdata(colorVid);
        idx = find(depthMetaData.IsSkeletonTracked);
        ax = subplot(2,2,1);
        set(ax, 'position', [0.09,0.43 0.41 0.55]);
        imshow(colorFrameData);
        
        % ���� ó��
        % ���̷��� ������ ���� ��
        if idx ~= 0
            % ������ ��ġ ����
            rightHand = depthMetaData.JointDepthIndices(12,:,idx);
            
            % ������ �����Ͱ� ����
            zCoord = 1e3*min(depthMetaData.JointWorldCoordinates(12,:,idx));
            radius = round(90 - zCoord / 50);
            rightHandBox = [rightHand-0.5*radius 1.2*radius 1.2*radius];
            
            % �簢������ ������ ũ��
            rectangle('position', rightHandBox, 'EdgeColor', [1 1 0]);
            handDepthImage = imcrop(colorFrameData,rightHandBox);
            
            % ������ ������ ���� ��
            if ~isempty(handDepthImage)
                temp = imresize(handDepthImage, [224 224]);
                
                % ���۳��� Ȱ���� ��� ����
                YPred = classify(net,temp);
                result = string(YPred);
                
                accuracyR(countT) = result;
                %��ħ�� ���ϴ� ���� ������ �� �� ���� ��� �� ������ ����
                if result == '��'
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
                            if (q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��')&&(q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||    q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��')&&(q.get(i+2) == '��' || q.get(i+2) == '��' || q.get(i+2) == '��' || q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��')
                                switch(q.get(i))
                                    case '��'
                                        temp2 = temp2 + (cho1(1)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(3)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(4)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(6)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(7)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(8)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(10)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(12)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(13)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(15)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(16)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(17)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(18)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(19)*588);
                                end
                            elseif (q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��')&&(q.get(i+1)=='��'||q.get(i+1)=='��')&&(q.get(i+2)=='��'||q.get(i+2)=='��'||q.get(i+2)=='��'||q.get(i+2)=='��'||q.get(i+2)=='��')
                                switch(q.get(i))
                                    case '��'
                                        temp2 = temp2 + (cho1(1)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(3)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(4)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(6)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(7)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(8)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(10)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(12)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(13)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(15)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(16)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(17)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(18)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(19)*588);
                                end
                            elseif (q.get(i) == '��'||q.get(i) == '��')&&(q.get(i+1)=='��'||q.get(i+1)=='��'||q.get(i+1)=='��'||q.get(i+1)=='��'||q.get(i+1)=='��')&&(q.get(i+2) == '��' || q.get(i+2) == '��' || q.get(i+2) == '��' || q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��')
                                if q.get(i) =='��'
                                    switch(q.get(i+1))
                                        case '��'
                                            temp2 = temp2 + (jung1(10)*28);
                                        case '��'
                                            temp2 = temp2 + (jung1(11)*28);
                                        case '��'
                                            temp2 = temp2 + (jung1(12)*28);
                                    end
                                    
                                elseif q.get(i) =='��'
                                    switch(q.get(i+1))
                                        case '��'
                                            temp2 = temp2 + (jung1(15)*28);
                                        case '��'
                                            temp2 = temp2 + (jung1(16)*28);
                                        case '��'
                                            temp2 = temp2 + (jung1(17)*28);
                                    end
                                end
                                q.remove();
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == '��'||q.get(i) == '��')&&(q.get(i+1)=='��'||q.get(i+1)=='��'||q.get(i+1)=='��'||q.get(i+1)=='��'||q.get(i+1)=='��'||q.get(i+1)=='��')&&q.get(i+2)=='!'
                                if q.get(i) =='��'
                                    switch(q.get(i+1))
                                        case '��'
                                            temp2 = temp2 + (jung1(10)*28);
                                        case '��'
                                            temp2 = temp2 + (jung1(11)*28);
                                        case '��'
                                            temp2 = temp2 + (jung1(12)*28);
                                    end
                                    
                                elseif q.get(i) =='��'
                                    switch(q.get(i+1))
                                        case '��'
                                            temp2 = temp2 + (jung1(15)*28);
                                        case '��'
                                            temp2 = temp2 + (jung1(16)*28);
                                        case '��'
                                            temp2 = temp2 + (jung1(17)*28);
                                    end
                                end
                                q.remove();
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||    q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��')&&(q.get(i+1) == '��' || q.get(i+1) == '��' || q.get(i+1) == '��' || q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��')&&(q.get(i+2) == '��' || q.get(i+2) == '��' || q.get(i+2) == '��' || q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��' ||q.get(i+2) == '��')
                                switch(q.get(i))
                                    case  '��'
                                        temp2 = temp2 + (jung1(1)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(2)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(3)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(4)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(5)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(6)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(7)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(8)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(9)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(12)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(13)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(14)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(17)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(18)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(19)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(20)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(21)*28);
                                end
                            elseif (q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||    q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��')&&(q.get(i+1) == '��' || q.get(i+1) == '��' || q.get(i+1) == '��' || q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��')&&(q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||    q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��')
                                switch(q.get(i))
                                    case  '��'
                                        temp2 = temp2 + (jung1(1)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(2)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(3)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(4)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(5)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(6)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(7)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(8)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(9)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(12)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(13)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(14)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(17)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(18)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(19)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(20)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(21)*28);
                                end
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��')&&(q.get(i+1) == '��' || q.get(i+1) == '��' || q.get(i+1) == '��' || q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��')&&(q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||    q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��'||q.get(i+2) == '��')
                                switch(q.get(i))
                                    case  '��'
                                        temp2 = temp2 + jong1(2);
                                    case  '��'
                                        temp2 = temp2 + jong1(5);
                                    case  '��'
                                        temp2 = temp2 + jong1(8);
                                    case  '��'
                                        temp2 = temp2 + jong1(9);
                                    case  '��'
                                        temp2 = temp2 + jong1(17);
                                    case  '��'
                                        temp2 = temp2 + jong1(18);
                                    case  '��'
                                        temp2 = temp2 + jong1(20);
                                    case  '��'
                                        temp2 = temp2 + jong1(22);
                                    case  '��'
                                        temp2 = temp2 + jong1(23);
                                    case  '��'
                                        temp2 = temp2 + jong1(24);
                                    case  '��'
                                        temp2 = temp2 + jong1(25);
                                    case  '��'
                                        temp2 = temp2 + jong1(26);
                                    case  '��'
                                        temp2 = temp2 + jong1(27);
                                    case  '��'
                                        temp2 = temp2 + jong1(28);
                                end
                                q.remove();
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��')&&q.get(i+1)=='!'&&q.get(i+2)=='@'
                                switch(q.get(i))
                                    case  '��'
                                        temp2 = temp2 + jong1(2);
                                    case  '��'
                                        temp2 = temp2 + jong1(5);
                                    case  '��'
                                        temp2 = temp2 + jong1(8);
                                    case  '��'
                                        temp2 = temp2 + jong1(9);
                                    case  '��'
                                        temp2 = temp2 + jong1(17);
                                    case  '��'
                                        temp2 = temp2 + jong1(18);
                                    case  '��'
                                        temp2 = temp2 + jong1(20);
                                    case  '��'
                                        temp2 = temp2 + jong1(22);
                                    case  '��'
                                        temp2 = temp2 + jong1(23);
                                    case  '��'
                                        temp2 = temp2 + jong1(24);
                                    case  '��'
                                        temp2 = temp2 + jong1(25);
                                    case  '��'
                                        temp2 = temp2 + jong1(26);
                                    case  '��'
                                        temp2 = temp2 + jong1(27);
                                    case  '��'
                                        temp2 = temp2 + jong1(28);
                                end
                                q.remove();
                                q.remove();
                                q.remove();
                                break;
                            elseif (q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' || q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��' ||q.get(i) == '��')&&(q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||    q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��'||q.get(i+1) == '��')&&q.get(i+2)=='!'
                                switch(q.get(i))
                                    case '��'
                                        temp2 = temp2 + (cho1(1)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(3)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(4)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(6)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(7)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(8)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(10)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(12)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(13)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(15)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(16)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(17)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(18)*588);
                                    case '��'
                                        temp2 = temp2 + (cho1(19)*588);
                                end
                            elseif (q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||    q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��')&&(q.get(i+1) == '��' || q.get(i+1) == '��' || q.get(i+1) == '��' || q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��' ||q.get(i+1) == '��')&&q.get(i+2)=='!'
                                switch(q.get(i))
                                    case  '��'
                                        temp2 = temp2 + (jung1(1)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(2)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(3)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(4)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(5)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(6)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(7)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(8)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(9)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(12)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(13)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(14)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(17)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(18)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(19)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(20)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(21)*28);
                                end
                            elseif (q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||    q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��'||q.get(i) == '��')&&q.get(i+1)=='!'&&q.get(i+2)=='@'
                                switch(q.get(i))
                                    case  '��'
                                        temp2 = temp2 + (jung1(1)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(2)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(3)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(4)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(5)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(6)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(7)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(8)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(9)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(12)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(13)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(14)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(17)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(18)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(19)*28);
                                    case  '��'
                                        temp2 = temp2 + (jung1(20)*28);
                                    case  '��'
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
                    %����� ������ ��¹� tts ��� 
                    set(b,'String', char(temp1),'position',[80 130 650 120])
                    tts(char(temp1))
                    %����� ť ���� 
                    for m=0:q.size()-1
                        q.remove();
                    end
                    %�������� �ʱ�ȭ
                    temp1 = [];
                    %���� ����
                    stop(depthVid);
                    stop(colorVid);
                    stop(t);
                end
                %��Ȯ�� ������ ���� 5���� ���� ������ q�� ����
                if countT == 5
                    if accuracyR(1) == accuracyR(2) && accuracyR(2) == accuracyR(3) && accuracyR(3) == accuracyR(4) && accuracyR(4) == accuracyR(5)
                        set(d,'String', char(accuracyR(2)),'position',[420 440 320 120])
                         % tts ��� ��� �� q�� ����
                        tts(char(accuracyR(2)))
                        q.add(char(accuracyR(1)));
                    end
                    countT = 0;
                end
                countT = countT + 1;
            end
        end
        
        
    end

% ���� �Լ� ����
    function dispDepth2(obj, event)
        
        % ���� ���
        trigger(depthVid);
        trigger(colorVid);
        [depthMap, ~, depthMetaData] = getdata(depthVid);
        [colorFrameData] = getdata(colorVid);
        idx = find(depthMetaData.IsSkeletonTracked);
        ax = subplot(2,2,1);
        set(ax, 'position', [0.09,0.43 0.41 0.55]);
        imshow(colorFrameData);
        
        % ����ó��
        % ���̷��� ������ ���� ��
        if idx ~= 0
            
            % ô�� ��ġ ��� ��ݽ� ����
            body = depthMetaData.JointDepthIndices(3,:,idx);
            
            % �簢������ ��ݽ� ũ��
            radius = 300;
            bodyBox = [body(1)-0.75*radius body(2)-0.3*radius 1.5*radius radius];
            rectangle('position', bodyBox, 'EdgeColor', [1 1 0]);
            bodyImage = imcrop(colorFrameData,bodyBox);
            
            % ũ���� ���� ��
            if ~isempty(bodyImage)
                
                % timer �Լ��� �Ҹ� ������ m����
                m=m+1;
                
                % �̹��� ������¡ �� ����
                k(:,:,:,m)= uint8(imresize(bodyImage,[300,450]));
                
                % 10���������� 3�� ����
                if(m==30)
                    
                    % ������ �̹����� ������ ����
                    video = centerCrop(k,inputSize);
                    
                    % ������ ���۳ݿ� �˸��� �����ͷ� ��ȯ
                    sequences{1}= activations(netCNN,video,layerName,'OutputAs','columns');
                    
                    % ���۳��� Ȱ���� ��� ����
                    YPred = classify(netLSTM,sequences);
                    result = string(YPred);
                    
                   
                    % tts�� ��� ���
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

% �� ��ɿ� ���� callback �Լ� ����
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
         %��ž ������ ����� ������ �������� ����
                        if q.size()-1 == 2
                            for y=0:q.size()-1
                                if y==0
                                    temp3(y+1) = char(q.get(y)+"��");
                                elseif y==1
                                    temp3(y+1) = char(q.get(y)+"��"+" ");
                                elseif y==2
                                    temp3(y+1) = char(q.get(y)+" ");
                                end
                            end
                        else
                            for y=0:q.size()-1
                                temp3(y+1) = char(q.get(y)+" ");
                            end
                        end
                        %q������ ����
                        for m=0:q.size()-1
                            q.remove();
                        end
                        
                        newstr = join(temp3);
                        %���� ���
                        set(b,'String', char(temp3),'position',[80 130 650 120])
                        tts(char(newstr))
                        %�������� �ʱ�ȭ
                        temp3 = [""];
                        newstr = "";
                        %���� ����
                        stop(depthVid);
                        stop(colorVid);
                        stop(t2);
    end

    function speechCallback(obj, event)
        start(t3);
        stop(t3);
    end
end

% ���� ������¡ �Լ� ����
function videoResized = centerCrop(video,inputSize)

% ���� ������ ����
sz = size(video);

% ������ ǳ���� ��
if sz(1) < sz(2)
    idx = floor((sz(2) - sz(1))/2);
    video(:,1:(idx-1),:,:) = [];
    video(:,(sz(1)+1):end,:,:) = [];
    
    % ������ �ι��� ���� ��
elseif sz(2) < sz(1)
    
    idx = floor((sz(1) - sz(2))/2);
    video(1:(idx-1),:,:,:) = [];
    video((sz(2)+1):end,:,:,:) = [];
end

% ���� ������ ��ȯ
videoResized = imresize(video,inputSize(1:2));

end