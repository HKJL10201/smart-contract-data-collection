// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Election
{
    error notOwner(address sender);
    error votingClosed(bool flag);
    error addCandidateError(address candidate);
    error notEnoughMoney(uint256 votersMoney, uint256 minimumMoney);
    error alreadyVoted(address voter);
    error defunctCandidate(address candidate);
    error votingIsNotOver(bool flag);
    error votingHasEnded(bool flag);
    error votingIsNotCompleted(bool flag);

    event Paid(address indexed _from, uint indexed _amount);
    address public owner;

    modifier votingOpen(string calldata _topic)
    {
        if( voitingMap[keccak256(abi.encode(_topic))].endTime < block.timestamp)
        {
            revert votingClosed(false);
        }
        _;
    }

    modifier onlyOwner() 
    {
        if(msg.sender != owner)
        {
            revert notOwner(msg.sender);
        }
        _;
    }

    constructor()
    {
        owner = msg.sender;
    }

    /**
     * @dev Special bulletin for voting
     */
    struct ballot 
    {

    /**
     * @dev It will become true if someone completes the vote
    */
    bool flag;

    uint256 balance;
    uint256 endTime;

    /**
    * @dev those who voted
    */
    mapping(address => bool) voters;

    /**
    * @dev Storage of candidates taking part in the voting
    */
    mapping(address => uint) candidates;

    address winner;
    }

    mapping(bytes32 => ballot) voitingMap;


    function startBallot (string calldata _topic) external onlyOwner returns (bool)
    {
        
        ballot storage newBallot = voitingMap[keccak256(abi.encode(_topic))];
        newBallot.endTime = block.timestamp + 3 days;

        return true;
    }

    function addCandidate(string calldata _topic, address _address) external onlyOwner returns (bool)
    {
        bytes32 ballotHash = keccak256(abi.encode(_topic));
        if(voitingMap[ballotHash].candidates[_address] != 0)
        {
            revert addCandidateError(_address);
        }

        voitingMap[ballotHash].candidates[_address]++;

        return true;
    }

    function vote(string calldata _topic, address _address) external payable votingOpen(_topic) returns (bool)
    {
        if (msg.value < 0.01 ether)
        {
           revert notEnoughMoney(msg.value, 0.01 ether);
        }

        bytes32 ballotHash = keccak256(abi.encode(_topic));

        if (voitingMap[ballotHash].voters[msg.sender])
        {
            revert alreadyVoted(msg.sender);
        }

        if (voitingMap[ballotHash].candidates[_address] < 1)
        {
            revert defunctCandidate(_address);
        }

        voitingMap[ballotHash].balance += msg.value;
        voitingMap[ballotHash].candidates[_address]++;
        voitingMap[ballotHash].voters[msg.sender] = true;

        if (voitingMap[ballotHash].candidates[_address] > voitingMap[ballotHash].candidates[voitingMap[ballotHash].winner])
        {
            voitingMap[ballotHash].winner = _address;
        }
        emit Paid(msg.sender, msg.value);

        return true;
    }

    function getWinner(string calldata _topic) view external returns(address)
    {
        return voitingMap[keccak256(abi.encode(_topic))].winner;
    }

    function finish(string calldata _topic) external payable returns (bool)
    {
        bytes32 ballotHash = keccak256(abi.encode(_topic));

        if ( block.timestamp <= voitingMap[ballotHash].endTime)
        {
            revert votingIsNotOver(false);
        }

        if (voitingMap[ballotHash].flag)
        {
            revert votingHasEnded(false);
        }

        voitingMap[ballotHash].flag = true;
        
        payable(voitingMap[ballotHash].winner).transfer((voitingMap[ballotHash].balance * 9) / 10);
        voitingMap[ballotHash].balance -= (voitingMap[ballotHash].balance * 9) / 10 ;

        return true;
    }

    function Withdrawal(string calldata _topic, address payable _to) external onlyOwner payable returns (bool)
    {
        if (!voitingMap[keccak256(abi.encode(_topic))].flag)
        {
            revert votingIsNotCompleted(false);
        }

        _to.transfer(voitingMap[keccak256(abi.encode(_topic))].balance);
        return true;
    }
}