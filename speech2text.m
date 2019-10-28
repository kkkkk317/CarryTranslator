% speech2text.m
% STT(Speech To Text) 기능 실행 함수
function tableOut = speech2text(connection, y, fs, varargin)

% Connection이 되고, 해당 class-type이 맞는지 확인
assert(~isempty(connection) && isa(connection, 'BaseSpeechClient') && isvalid(connection), ...
    'The first input to the speech2text function should be a speechClient object');

% timeout 기본값 지정
timeOut = 10;

% HTTP의 timeout 값을 가져옴
if ~isempty(varargin)
    validatestring(varargin{1},{'HTTPTimeOut'});
    timeOut = varargin{2};
end

% speechClient의 에서 STT 함수를 불러옴
tableOut = connection.speechToText(y,fs,timeOut);

end
