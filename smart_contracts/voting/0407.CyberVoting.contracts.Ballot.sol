// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ballot {
    struct vote {
        address voterAddress;
        bool option;
    }

    struct voter {
        string voterName;
        bool voted;
    }

    struct proposal {
        string proposalName;
        string proposalContent;
    }
    // count the result of each vote when the ballot in state happens
    uint private countResult = 0;
    // for people to view the final result
    uint public finalResult = 0;
    // total of voter in the network
    uint public totalVoter = 0;
    // total vote in network
    uint public totalVote = 0;

    address public ballotOfficialAddress;
    string public ballotOfficialName;
    proposal public ballotProposal;

    // store information about the index of vote on each voter
    mapping(uint => vote) private votes;
    // store voter
    mapping(address => voter) public voterRegister;

    enum State {
        Created,
        Voting,
        Ended
    }

    State public state;

    //creates a new ballot contract
    constructor(
        string memory _ballotOfficialName,
        string memory _proposalName,
        string memory _proposalContent
    ) {
        ballotOfficialAddress = msg.sender;
        ballotOfficialName = _ballotOfficialName;
        ballotProposal = proposal({
            proposalName: _proposalName,
            proposalContent: _proposalContent
        });

        state = State.Created;
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }
    modifier onlyOfficial() {
        require(msg.sender == ballotOfficialAddress);
        _;
    }
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    event voterAdded(address voter);
    event voteStarted();
    event voteEnded(uint finalResult);
    event voteDone(address voter);

    // add voter
    function addVoter(
        address _voterAddress,
        string memory _voterName
    ) public inState(State.Created) onlyOfficial {
        voter memory temp_v;
        temp_v.voterName = _voterName;
        temp_v.voted = false;
        voterRegister[_voterAddress] = temp_v;
        totalVoter++;

        // fire a event
        emit voterAdded(_voterAddress);
    }

    function startVote() public inState(State.Created) onlyOfficial {
        state = State.Voting;
        emit voteStarted();
    }

    function doVote(
        bool _option
    ) public inState(State.Voting) returns (bool voted) {
        bool flag = false;
        if (
            bytes(voterRegister[msg.sender].voterName).length != 0 &&
            !voterRegister[msg.sender].voted
        ) {
            // change state of voted to true
            voterRegister[msg.sender].voted = true;

            // create temp voter to store information about each vote
            vote memory temp_v;
            temp_v.voterAddress = msg.sender;
            temp_v.option = _option;
            if (_option) {
                countResult++;
            }
            votes[totalVote] = temp_v;
            totalVote++;
            flag = true;
        }
        emit voteDone(msg.sender);
        return flag;
    }

    function endVote() public inState(State.Voting) onlyOfficial {
        state = State.Ended;
        finalResult = countResult;
        emit voteEnded(finalResult);
    }
}
