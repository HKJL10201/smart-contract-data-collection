pragma solidity >=0.4.21 <0.6.0;
// pragma experimental ABIEncoderV2;

contract Poll {

    struct Option {
        uint id;
        string option;
        uint voteCount;
    }

    struct Question {
        uint id;
        address owner;
        string question;
        uint optionCount;
        bool active;
    }

    mapping(uint => Question) public polls;
    mapping(uint => Option[]) public options;
    uint public pollsCount;
    uint optionsCount;

    mapping (bytes32=>bool) voters;

    function addPollQuestion (string memory _question, uint _optionCount) public {
        require(_optionCount>0);
        pollsCount++;
        polls[pollsCount].id = pollsCount;
        polls[pollsCount].owner = msg.sender;
        polls[pollsCount].question = _question;
        polls[pollsCount].optionCount = _optionCount;
    }

    function addPollOption (string memory _option, uint _pollId) public {
        require(msg.sender==polls[_pollId].owner);
        require(options[_pollId].length<polls[_pollId].optionCount);
        options[_pollId].push(Option({id : options[_pollId].length, option : _option, voteCount : 0}));
    }

    function changePollStatus (uint _pollId) public {
        require(msg.sender==polls[_pollId].owner);
        if(!polls[_pollId].active){
            polls[_pollId].active = true;
        }else{
            polls[_pollId].active = false;
        }
    }

    function voteOption (uint _pollId, uint _optionId) public {
        require(polls[_pollId].active);
        require(!voters[keccak256(abi.encodePacked(_pollId, msg.sender))]);
        voters[keccak256(abi.encodePacked(_pollId, msg.sender))] = true;
        options[_pollId][_optionId].voteCount++;
    }

}