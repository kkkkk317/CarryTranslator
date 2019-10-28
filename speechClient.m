% speechClient.m
% STT를 실행하기위한 client 호출 함수
function clientObj = speechClient(apiName,varargin)

% String의 valid 체크
narginchk(1,Inf);
validatestring(apiName,{'Google','IBM','Microsoft'},'speechClient','apiName');

% api의 type에 따라 불러오는 client가 다름
switch apiName
    case 'Google'
        clientObj = GoogleSpeechClient.getClient();
    case 'IBM'
        clientObj = IBMSpeechClient.getClient();
    case 'Microsoft'
        clientObj = MicrosoftSpeechClient.getClient();
end

% client object의 option 지정
clientObj.clearOptions();
clientObj.setOptions(varargin{:});

end