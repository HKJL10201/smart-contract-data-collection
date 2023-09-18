// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract votingDapp {
    /// @dev state variables
    uint ID = 0;
    uint32 timeOut;
    address owner;
    bool started;
    bool _end;

    constructor() {
        owner = msg.sender;
    }

    /// @dev the struct for the candidate details

    struct candidateDetails {
        address PartyAddress;
        string partyName;
        uint NOofVotes;
        bool registered;
    }

    /// @dev modifiers

    modifier OnlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @dev custom errors

    /// 5 ethers for registration
    error NotEnoughFunds();

    /// zero address not allowed
    error addressZero();

    /// you can vote once please
    error revertVote();

    /// @dev mappings

    mapping(uint => candidateDetails) public allCandidatesDetail;

    mapping(address => bool) voted;

    mapping(address => bool) registered;

    /// @dev events

    event registers(uint indexed, string indexed _partyName);
    event elected(address voter, uint indexed partyId);
    event ended(uint winner, uint noOfVotes);

    /// @dev start candidate registers for the election which is 5 ether

    function register(string memory _partyName) external payable {
        if (msg.value != 5 ether) {
            revert NotEnoughFunds();
        }
        if (msg.sender == address(0)) {
            revert addressZero();
        }
        require(registered[msg.sender] != true);
        candidateDetails storage CDs = allCandidatesDetail[ID];
        CDs.partyName = _partyName;
        CDs.PartyAddress = msg.sender;
        CDs.registered = true;
        ID++;

        registered[msg.sender] = true;
        emit registers(ID, _partyName);
    }

    /// @dev the election lasts for a day and the owner of contract start the election

    function start() external OnlyOwner {
        require(!started, "started");
        started = true;
        timeOut = uint32(block.timestamp + 1 minutes);
    }

    function election(uint candateIndex) external {
        if (voted[msg.sender] == true) {
            revert revertVote();
        }
        require(block.timestamp <= timeOut, "election ended");
        require(started == true, "not started");
        candidateDetails storage CDs = allCandidatesDetail[candateIndex];
        CDs.NOofVotes++;
        voted[msg.sender] = true;

        emit elected(msg.sender, candateIndex);
    }

    function end()
        external
        OnlyOwner
        returns (uint256 winner, address winner_addr)
    {
        require(block.timestamp >= timeOut, "election in program");
        require(started == true, "not started");
        require(_end != true, "ended");
        for (uint i = 0; i <= ID; i++) {
            if (winner > allCandidatesDetail[i].NOofVotes) {
                winner = allCandidatesDetail[i].NOofVotes;
                winner_addr = allCandidatesDetail[i].PartyAddress;
            }
        }
        _end = true;
    }

    receive() external payable {}
}
