pragma solidity 0.8.11;

contract Voter {

    struct Candidate {
        string name;
        address payable victoryAccount;
        uint voteCount;
    }

    address payable internal sourceAddress;
    uint internal victoryAmount;

    mapping(address => Candidate) private candidates;

    mapping(address => bool) private voters;

    Candidate private winner;

    //Require initial payment in etherium to be sent to the victory account once decision is made.
    constructor() payable {
        victoryAmount = msg.value;
        sourceAddress = payable(msg.sender);
    }

    function addCandidate(string memory _name, address payable _victoryAccount) public {
        //require that candidate address does not exist already.
        require(_victoryAccount != address(0), "Victory account can not be 0x0");
        require(candidates[_victoryAccount].victoryAccount == address(0), "Candidate already registered.");

        candidates[_victoryAccount] = Candidate(_name, _victoryAccount, 0);
    } 

    function vote(address _candidateAddress) external {
        Candidate storage c = candidates[_candidateAddress];
        //Require that the candidate exists with the _candidateAddress
        require(c.victoryAccount == _candidateAddress, "Candidate does not exist.");

        //Require that the voter has not already voted yet.
        require(!voters[msg.sender], "Voter has already voted!");

        voters[msg.sender] = true;
        c.voteCount++;
        if(c.voteCount > winner.voteCount) {
            winner = c;
        }
    }

    // Receive function to receive the ether funds. This is required otherwise contract will not be able to recieve funds
    // with empty calldata.
    receive() external payable {
        victoryAmount += msg.value;
    }


    //TODO: Secure this with ECDSA signature validation.
    function declareVictory() public {
        require(msg.sender == sourceAddress, "Only the initiator can conclude the victory.");
        require(winner.victoryAccount != address(0), "Voting has not commenced yet.");

        winner.victoryAccount.transfer(victoryAmount);
        selfdestruct(sourceAddress);
    }

    function getWinner() public view returns (string memory, address, uint, uint) {
        return (winner.name, winner.victoryAccount, winner.voteCount, victoryAmount);
    }
}