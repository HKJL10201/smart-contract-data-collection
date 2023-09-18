pragma solidity >0.4.22;

contract Voting{
    struct Survey{
        uint surveyId;
        string title;
        string registerEnd;
        string startTime;
        string endTime;
        string remark;
        string options;
    }
    struct AnswerCon{
        uint surveyId;
        string answer;
        string pkey;
    }
    Survey[] public surveyList;
    AnswerCon[] public answerConList;

    //注册合约 （surveyId,title，registerEnd，startTime，endTime，remark，options,q,g）,返回成功失败
    function registerContract(uint surveyId,string memory title,string memory registerEnd,string memory startTime,string memory endTime,string memory remark,string memory options) public{
        surveyList.push(Survey({
            surveyId: surveyId,
            title: title,
            registerEnd: registerEnd,
            startTime: startTime,
            endTime: endTime,
            remark: remark,
            options: options
        }));
    }
    //投票者注册 （pkeys,surveyId）
    function registerVoter(string memory pkey,uint surveyId) public{
        answerConList.push(AnswerCon({
            surveyId: surveyId,
            answer: "null",
            pkey: pkey
        }));
    }
    //检查注册的合约,返回成功失败 
    function getSurvey(uint surveyId,string memory title,string memory registerEnd,string memory startTime,string memory endTime,string memory remark,string memory options) public view returns(bool){
        bool success = false;
        for(uint i = 0;i<surveyList.length;i++){
            if(surveyList[i].surveyId == surveyId){
                if(keccak256(abi.encodePacked(surveyList[i].title)) == keccak256(abi.encodePacked(title))){
                    if(keccak256(abi.encodePacked(surveyList[i].registerEnd)) == keccak256(abi.encodePacked(registerEnd))){
                        if(keccak256(abi.encodePacked(surveyList[i].startTime)) == keccak256(abi.encodePacked(startTime))){
                            if(keccak256(abi.encodePacked(surveyList[i].endTime)) == keccak256(abi.encodePacked(endTime))){
                                if(keccak256(abi.encodePacked(surveyList[i].remark)) == keccak256(abi.encodePacked(remark))){
                                    if(keccak256(abi.encodePacked(surveyList[i].options)) == keccak256(abi.encodePacked(options))){
                                        success = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            break;
        }
        return success;
    }
    //投票者投票(surveyId,answer),
    function votingVoter(uint surveyId,string memory answer) public{
        for(uint i = 0;i<answerConList.length;i++){
            if(answerConList[i].surveyId == surveyId){
                answerConList[i].answer = answer;
            }
        }
    }
    //统计 (surveyId,answer[]),返回成功失败 (在前端反复调用 )
    function statistics(uint surveyId,string memory answer) public view returns(bool){
        bool success = false;
        for(uint i = 0;i<answerConList.length;i++){
            if(answerConList[i].surveyId == surveyId){
                if(keccak256(abi.encodePacked(answerConList[i].answer)) == keccak256(abi.encodePacked(answer))){
                    success = true;
                }
            }
            break;
        }
        return success;
    }
    //指数运算
    function pow(uint a,uint b) internal pure returns(uint res){
        res = 1;
        for(uint i = 0;i<b;i++){
            res = res * a;
        }
        return res;
    }
}
