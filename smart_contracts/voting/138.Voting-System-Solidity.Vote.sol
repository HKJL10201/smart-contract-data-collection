// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract ParseStrings{
    function stringToBytes32(string memory _text) external pure returns (bytes32){
        return bytes32(bytes(_text));
    }

    function bytes32ToString(bytes32 _data) external pure returns (string memory){
        return string(abi.encodePacked(_data));
    }

    // 0x53616e746961676f000000000000000000000000000000000000000000000000 - > Santiago
    // 0x5061626c6f000000000000000000000000000000000000000000000000000000 - > Pablo
}

contract CEOVote is ParseStrings{
    struct Voter{
        bool voted;
        bool canVote;
        uint256 candidateIndex;
    }

    struct Candidate{
        bytes32 name;
        uint256 voteCount;
    }

    mapping(address => Voter) public voters;

    address public admin;
    bool public isActive = true;
    uint256 public startDate = block.number;

    Candidate[2] public candidates;

    event Vote(bytes32 indexed _canditate);

    modifier onlyAdmin{
        require(msg.sender == admin, "Only admin allow");
        _;
    }
    
    constructor(bytes32 _candidateOne, bytes32 _candidateTwo){
        admin = msg.sender;
        candidates[0] = Candidate({
            name: _candidateOne,
            voteCount: 0
        });

        candidates[1] = Candidate({
            name: _candidateTwo,
            voteCount: 0
        });
    }

    function vote(uint256 _canditate) external{
        Voter storage sender = voters[msg.sender];
        require(sender.canVote, "You cannot participate");
        require(_canditate < 2, "Invalid vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.candidateIndex = _canditate;

        candidates[_canditate].voteCount++;
        if(candidates[_canditate].voteCount > 2 || block.number > startDate + 11520){
            finishVoting();
        }
    }

    function giveRightToVote(address _voter) external onlyAdmin{
        require(!voters[_voter].voted, "Already voted");
        voters[_voter].canVote = true;
    }

    function finishVoting() internal{
        isActive = false;
    }
    
    function winningName() public view returns(bytes32){
        require(!isActive, "Still active");
        if(candidates[0].voteCount > candidates[1].voteCount){
            return candidates[0].name;
        }else{
            return candidates[1].name;
        }
    }
}

interface ICEOVote{
    function winningName() external view returns(bytes32);
    function isActive() external view returns(bool);
}


contract CEOBet{
    struct Gambler{
        bytes32 userBet;
        bool alreadyBet;
    }

    ICEOVote public target;

    mapping(address => Gambler) public gamblers;
    mapping(address => bool) public isWhitelisted;

    constructor(address one, address two, ICEOVote _target){
        target = _target;
        isWhitelisted[one] = true;
        isWhitelisted[two] = true;
    }

    function getStatus() public view returns(bool){
        return ICEOVote(target).isActive();
    } 

    function bet(bytes32 _candidate) public payable{
        bool isActive = getStatus();
        require(isActive, "Already finished");
        require(isWhitelisted[msg.sender], "You cannot participate");
        require(msg.value == 1 ether, "Must bet one ether");
        require(!gamblers[msg.sender].alreadyBet, "Already Bet");
        Gambler storage gambler = gamblers[msg.sender];
        gambler.alreadyBet = true;
        gambler.userBet = _candidate;
    }

    function claim() public{
        bool isActive = getStatus();
        require(!isActive, "Still Active");
        require(isWhitelisted[msg.sender], "You cannot participate");
        require(gamblers[msg.sender].userBet == ICEOVote(target).winningName(), "Is not the winner");
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transaction fail");
    }
}