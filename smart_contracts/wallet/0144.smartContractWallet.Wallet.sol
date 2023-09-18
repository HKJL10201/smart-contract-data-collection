//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract SmartContractWallet {

    //Global Variables
    address payable public owner;
    uint public ContractBalance;

    //Mappings
    mapping(uint => Guardian) public Guardians;
    mapping(uint => limitRequest) public Requests;

    //Counters
    uint public requestCounter;

    //Structures
    struct Guardian {
        address guardianAddress;
        uint limit;
        address Owner;
    }

    struct limitRequest {
        address submitter;
        uint increase;
        uint votesFor;
        uint votesAgainst;
        uint alreadyVotedCounter;
        mapping(uint => address) alreadyVoted;
        uint status; //2 - PENDING 1 - DECLINED 0 - APPROVED
    }

    constructor() {
        owner = payable(msg.sender);

        Guardians[0].guardianAddress = 0x3a1774a9D219B7b052bbc1f184096c7d572042e4;
        Guardians[1].guardianAddress = 0xda0a841D2915b1cA042d967899625bf4d13aCCe1;
        Guardians[2].guardianAddress = 0xaCA9AA44b21551F649382D4A53fAa7135C2fd273;
        Guardians[3].guardianAddress = 0x9d94Fcd345bdC3E3ddbb954E5B37077CEcBB4e3e;
        Guardians[4].guardianAddress = 0x3043fD06e467BA5C459255e0C7d36e1B91759aCD;

        Guardians[0].limit = 1000000000000000000;
        Guardians[1].limit = 1000000000000000000;
        Guardians[2].limit = 1000000000000000000;
        Guardians[3].limit = 1000000000000000000;
        Guardians[4].limit = 1000000000000000000;
    }

    function deposit() public payable {
        ContractBalance += msg.value;
    }

    function setOwner(address payable _newAddress) public {
        
        uint guardianNumber = verifyGuardian(msg.sender);

        //Set new prefered address for guardian
        Guardians[guardianNumber].Owner = _newAddress;

        //Check to see if requirements are met for new owner.
        uint voterCount;
        for(uint i = 0; i < 5; i++) {
            if (Guardians[i].Owner == _newAddress) {
                voterCount++;
            }
        }
        if (voterCount >= 3) {
            owner = _newAddress;
        }
    }

    function Withdrawal(address payable _to, uint _amount) public {
        if (msg.sender == owner) {
            ContractBalance -= _amount;
            _to.transfer(_amount);
        } else {
            //Verify Guardian status
            uint guardianNumber = verifyGuardian(msg.sender);

            //Must be lower or equal to authorised limit
            require(_amount <= Guardians[guardianNumber].limit, "Spending limit too low. Will need will to increase with approval first.");

            ContractBalance -= _amount;
            Guardians[guardianNumber].limit -= _amount;
            _to.transfer(_amount);
        }
    }

    //REQUEST FUNCTIONS
    function requestIncreaseSpendingLimit(uint _increase) public {
        verifyGuardian(msg.sender);
        require(_increase > 0, "Increase must be greater than zero");

        uint internalCounter = requestCounter;
        requestCounter ++;

        //Set peramaters of request
        Requests[internalCounter].submitter = msg.sender;
        Requests[internalCounter].increase = _increase;
        Requests[internalCounter].status = 2;
    }

    function voteOnRequests(uint _requestNumber, uint yesNo) public {

        //Check if request is already actioned
        bool alreadyActioned = true;
        if(Requests[_requestNumber].status == 1 || Requests[_requestNumber].status == 0) {
            alreadyActioned = false;
        }

        //Check if msg.sender has already voted
        bool alreadyVoted = true;
        for(uint i = 0; i < 5; i ++) {
            if (Requests[_requestNumber].alreadyVoted[i] == msg.sender) {
                alreadyVoted = false;
            }
        }

        //Contract exceptions
        verifyGuardian(msg.sender);
        require(yesNo == 0 || yesNo == 1, "Please use 0 for yes and 1 for no. Votes cannot be changed");
        require(alreadyActioned, "Request has already been cancelled or approved");
        require(msg.sender != Requests[_requestNumber].submitter, "Cannot vote on own request");
        require(alreadyVoted, "You have already voted on this request. Votes cannot be changed");

        //Record address voter for this request
        uint temporary = Requests[_requestNumber].alreadyVotedCounter;
        Requests[_requestNumber].alreadyVotedCounter++;
        Requests[_requestNumber].alreadyVoted[temporary] = msg.sender;

        //Vote
        if (yesNo == 0) {
            Requests[_requestNumber].votesFor++;
        } else {
            Requests[_requestNumber].votesAgainst++;
        }

        //Check if request can now be actioned
        if (Requests[_requestNumber].votesFor >= 3) {
            Requests[_requestNumber].status = 0;

            //Increase limit
            for(uint i = 0; i < 5; i++) {
                if(Requests[_requestNumber].submitter == Guardians[i].guardianAddress) {
                    Guardians[i].limit += Requests[_requestNumber].increase;
                }
            }
        }

        //Decline request
        if (Requests[_requestNumber].votesAgainst > 1) {
            Requests[_requestNumber].status = 1;
        }

    }

    function cancelRequest(uint _requestNumber) public {
        if ((msg.sender == Requests[_requestNumber].submitter) && (Requests[_requestNumber].status != 1 || Requests[_requestNumber].status != 0)) {
            Requests[_requestNumber].status = 1;
        }
    }

    //Throws an exception if not guardian. Returns guardian number if guardian
    function verifyGuardian(address _address) internal view returns(uint) {
        bool isGuardian = false;
        uint guardianNumber;

        for(uint i = 0; i < 5; i ++) {
            if(Guardians[i].guardianAddress == _address) {
                guardianNumber = i;
                isGuardian = true;
            }
        }
        require(isGuardian, "Only Guardians can make this request");

        return guardianNumber;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }
}