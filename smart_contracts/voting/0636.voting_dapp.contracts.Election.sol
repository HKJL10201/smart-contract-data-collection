// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// Pass dynamic arrays and structs between functions
pragma experimental ABIEncoderV2;

contract Election {
    address public owner;
    string public electionName;
    uint public candidateCount = 0;
    uint public voteCount;
    uint public startVote;
    uint public endVote;
    uint public startReg;
    uint public endReg;
    address[] public voterAddresses;
    uint256 MAX_INT = 2 ** 256 - 1;

    // Election Current state
    enum State {
        registrationNotStarted,
        registrationStarted,
        registrationEnded,
        electionStarted,
        electionEnded
    }

    State public state = State.registrationNotStarted;

    /**
     *	@dev Deployer sets the name of the election.
     *	Deployer is the owner of contract
     */
    constructor(string memory _name) {
        owner = msg.sender;
        electionName = _name;
        startVote = MAX_INT;
        endVote = MAX_INT;
        startReg = MAX_INT;
        endReg = MAX_INT;
    }

    struct Candidate {
        uint candidateId;
        string candidateName;
        uint partyId;
        uint candidateVoteCount;
        string uri; // May contain the link to profile picture or any metadata.
    }

    struct Voter {
        address voterId;
        uint256 citizenshipNumber;
        bool registered;
        uint256 vote;
        bool voted;
    }

    // Mappings
    mapping(uint => Candidate) candidates;
    mapping(address => Voter) public voters;

    // Events
    event NewCandidateAdded(
        uint candidateId,
        string candidateName,
        uint partyId,
        uint candidateVoteCount,
        string uri
    );

    event NewRegistration(address indexed from, uint citizenshipNumber);

    /**
     *	Only owner can call functions with this modifier
     *
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this");
        _;
    }

    /**
     *	Function with this modifer can only be called before _time.
     *
     */
    modifier onlyBefore(uint _time) {
        require(block.timestamp < _time, "Time for this action has exceeded");
        _;
    }

    /**
     *	Function with this modifer can only be called after _time.
     *
     */
    modifier onlyAfter(uint _time) {
        require(block.timestamp >= _time, "Wait for start");
        _;
    }

    /**
     *	@dev Can start election
     *  Election can start only after registration period expired.
     */
    function startElection() public onlyOwner onlyAfter(endReg) {
        startVote = block.timestamp;
        endReg = MAX_INT;
        state = State.electionStarted;
    }

    /**
     * @dev Can end election
     * Only owner can end the election
     */
    function endElection() public onlyOwner onlyAfter(startVote) {
        endVote = block.timestamp;
        startVote = MAX_INT;
        state = State.electionEnded;
    }

    /**
     *	@dev Can start registration
     *  Voters can be registered after registration starts
     */
    function startRegistration() public onlyOwner {
        startReg = block.timestamp;
        endVote = MAX_INT; // for second cycle of vote
        state = State.registrationStarted;
    }

    /**
     *	@dev Can end registration
     *  Voters can not be registered after registration ends
     */
    function endRegistration() public onlyOwner onlyAfter(startReg) {
        endReg = block.timestamp;
        startReg = MAX_INT;
        state = State.registrationEnded;
    }

    /**
     *	@dev Can register to vote in the election
     *  @param citizenshipNumber Their unique identification number (can be replaced with any unique data for that person)
     *  TODO:
     *		- An address who has aready registered can call this method again and again.
     * 		- Can be fixed by adding one key which represents if user has asked to register in Voter struct
     * 		- Set that to true when voter registers.
     * 		- Check that key is set to false before allowing to register
     */
    function registerAsVoter(
        uint256 citizenshipNumber
    ) public onlyAfter(startReg) onlyBefore(endReg) {
        require(
            voters[msg.sender].voterId == address(0),
            "Voter already registered"
        );
        voters[msg.sender] = Voter(
            msg.sender,
            citizenshipNumber,
            false, // default for the approval of registration
            0,
            false // default for the voted state
        );
        voterAddresses.push(msg.sender); // making list of addresses
        emit NewRegistration(msg.sender, citizenshipNumber);
    }

    /**
     *	@dev Returns the name of the election
     * 		 It is reduntant, as electionName variable is public
     */
    function getElectionName() public view returns (string memory) {
        return electionName;
    }

    /**
     *	@dev Can add candidates for an election
     *  @param _candidateName Name of the candidate
     *  @param _partyId Id representing political party they belong to
     *  @param _uri Metadata for the candidate
     */
    function addCandidates(
        string memory _candidateName,
        uint _partyId,
        string memory _uri
    ) public onlyBefore(startVote) onlyOwner {
        require(_partyId > 0, "The partyId shouldn't be zero");
        candidateCount++;
        candidates[candidateCount] = Candidate(
            candidateCount,
            _candidateName,
            _partyId,
            0,
            _uri
        );
        emit NewCandidateAdded(
            candidateCount,
            _candidateName,
            _partyId,
            0,
            _uri
        );
    }

    /**
     *	@dev Can get candidates data
     */
    function getCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory list = new Candidate[](candidateCount);
        for (uint256 i = 1; i <= candidateCount; i++) {
            list[i - 1] = candidates[i];
            list[i - 1].candidateVoteCount = 0;
        }
        return list;
    }

    /**
     * @dev Can get registered voter address for approval and voters stats
     */
    function getNonApprovedVoters() public view returns (Voter[] memory) {
        uint nonApprovedVoterCount = 0;
        // Iteration for size of list for nonApprovedVoters
        for (uint i = 0; i < voterAddresses.length; i++) {
            if (!voters[voterAddresses[i]].registered) {
                nonApprovedVoterCount++;
            }
        }
        Voter[] memory nonApprovedVoters = new Voter[](nonApprovedVoterCount);
        uint count = 0;
        for (uint i = 0; i < voterAddresses.length; i++) {
            if (!voters[voterAddresses[i]].registered) {
                nonApprovedVoters[count] = voters[voterAddresses[i]];
                count++;
            }
        }
        return nonApprovedVoters;
    }

    /**
     *	@dev Can approve voters
     *  @param _voter Address of the voter
     * 	TODO:
     * 		Voters who have not registered, can be approved.
     *		Can be fixed by adding one key which represents if user has asked to register in Voter struct
     */
    function approveVoters(
        address _voter
    ) public onlyBefore(startVote) onlyOwner {
        require(!voters[_voter].registered, "Voter has not registered yet");
        voters[_voter].registered = true;
    }

    /**
     *	@dev Can vote for their desired candidate
     *  @param _candidateId The candidateId of the desired candidate
     */
    function vote(uint _candidateId) public {
        require(startVote <= block.timestamp, "Election has not started yet.");
        require(endVote > block.timestamp, "Election is over.");

        Voter storage _voter = voters[msg.sender];

        require(!_voter.voted, "You have already voted");
        require(
            _voter.registered,
            "You are not registered/approved as a voter"
        );

        _voter.vote = _candidateId;
        candidates[_candidateId].candidateVoteCount++;
        voteCount++;
        _voter.voted = true;
    }

    /**
     *	@dev Can get Candidate who won the election
     */
    function checkResults()
        external
        view
        onlyAfter(endVote)
        returns (Candidate memory winningCandidateId)
    {
        uint highestVoteCount = 0;
        for (uint i = 1; i <= candidateCount; i++) {
            if (candidates[i].candidateVoteCount > highestVoteCount) {
                highestVoteCount = candidates[i].candidateVoteCount;
                winningCandidateId = candidates[i];
            }
        }
    }

    /**
     *	@dev Can get vote details for each candidate
     */
    function getFinalStats() external view returns (Candidate[] memory) {
        Candidate[] memory list = new Candidate[](candidateCount);
        for (uint256 i = 1; i <= candidateCount; i++) {
            list[i - 1] = candidates[i];
        }
        return list;
    }

    /**
     * @dev Can get ether balance of contract
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * @dev Can get particular candidate using candidate Id
     */
    function getCandidate(
        uint256 _candidateId
    ) public view returns (Candidate memory) {
        return candidates[_candidateId];
    }

    /**
     * @dev Can get particular candidate using candidate Id
     */
    function getVoter(
        address _voterAddress
    ) public view returns (Voter memory) {
        return voters[_voterAddress];
    }

    /**
     * @dev Can get owner of the contract
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @dev Can get contract internal State
     */
    function getCurrentState() public view returns (State) {
        return state;
    }

    /**
     * @dev Withdraw to a wallet
     * @param _to Address to transfer amount to
     * @param _amount Amount of ETH in wei
     */

    function withdraw(
        address payable _to,
        uint _amount
    ) external payable onlyOwner {
        require(address(this).balance >= _amount, "No enough fund to withdraw");
        payable(_to).transfer(_amount);
    }

    fallback() external payable {}

    receive() external payable {}
}
