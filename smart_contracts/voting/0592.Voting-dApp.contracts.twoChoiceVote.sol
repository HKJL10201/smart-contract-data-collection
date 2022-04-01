pragma solidity^0.7.0;

// yes or no voting contract

contract twoChoiceVote {

    address owner;
    uint agree = 0;
    uint disagree = 0;

    mapping(address => bool) registeredVotersMap;
    mapping(address => bool) hasVoted;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Must be contract owner.");
        _;
    }

    modifier isRegistered {
        require(registeredVotersMap[msg.sender], "Must be registered to vote.");
        _;
    }

    function addVoter (address _address) public onlyOwner {
        registeredVotersMap[_address] = true;
    }

    function removeVoter (address _address) public onlyOwner {
        registeredVotersMap[_address] = false;
    }


    function vote (bool _choice) public isRegistered {
        require(hasVoted[msg.sender] == false, "Vote already cast.");
        hasVoted[msg.sender] = true;

        if (_choice == true) {
            agree += 1;
        } else if (_choice == false) {
            disagree += 1;
        }
    }

    function getResults() public view returns(uint, uint) {
        return (agree, disagree);
    }


}