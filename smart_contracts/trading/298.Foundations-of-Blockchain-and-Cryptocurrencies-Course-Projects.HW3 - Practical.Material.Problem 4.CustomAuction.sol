pragma solidity ^ 0.5.1;

import "./Auction.sol";


contract CustomAuction is Auction {

    enum Phase {Pending, Commitment, Opening, Finished}
    Phase public phase;
    
    uint startPhaseBlock;
    uint commitment_len;
    uint opening_len;
    address payable lowestBidder;
    uint lowestBid;
    uint ReserveFund;
    bool firstOpen = true;
    
    struct Bid {
        bytes32 FileAddress;
        uint value;
        bytes32 hash;
        bytes32 nonce;
    }
    mapping(address => Bid) bids;
    
    // address of accounts admin choose in Opening phase
    mapping(address => bool) chooses;

    event openingStarted();
        
    constructor(address payable _admin, uint _commitment_len, uint _opening_len) public payable {
        // Control if inputs are valid or not and then initialize local variables
        require(_commitment_len > 0);
        require(_opening_len > 0);
        require(msg.value > 0);
        description.deployBlock = block.number;
        description.admin = _admin;
        startPhaseBlock = block.number;
        commitment_len = _commitment_len;
        opening_len = _opening_len;
        ReserveFund = msg.value;
        phase = Phase.Pending;
    }

    /// @dev This modifier allow to invoke the function olny during the Commitment phase.
    modifier duringCommitment {
        require(phase == Phase.Commitment);
        require(block.number <= startPhaseBlock + commitment_len);
        _;
    }

    /// @dev This modifier allow to invoke the function olny during the Opening phase.
    modifier duringOpening {
        require(phase == Phase.Opening);
        require(block.number <= startPhaseBlock + opening_len);
        _;
    }
    
    function getReserveFund() public view returns (uint256) {
        return ReserveFund;
    }
    
    function getFile(address add) public view returns (bytes32 fileAdd) {
        require(bids[add].FileAddress != 0);
        return bids[add].FileAddress;
    }
    
    /// @notice This function will activate the auction.
    function activateAuction() public onlyAdmin {
        require(phase == Phase.Pending);
        phase = Phase.Commitment;
        description.startBlock = block.number;
        startPhaseBlock = block.number;
        emit auctionStarted();
    }

    ///@notice This function allow people to make bid.
    ///@dev This function can be invoked only during the commitment phase.
    function bid(bytes32 _bidHash, bytes32 _FileAddress) public duringCommitment payable {
        require(_bidHash != 0 && _FileAddress != 0);
        require(bids[msg.sender].hash == 0 && bids[msg.sender].hash == 0);
        bids[msg.sender].hash = _bidHash;
        bids[msg.sender].FileAddress = _FileAddress;
    }

    ///@notice This function activate the Opening phase
    function startOpening(address add1, address add2, address add3) public onlyAdmin {
        require(phase == Phase.Commitment);
        require(block.number > startPhaseBlock + commitment_len);
        phase = Phase.Opening;
        startPhaseBlock = block.number;
        chooses[add1] = true;
        chooses[add2] = true;
        chooses[add3] = true;
        emit openingStarted();
    }
    
    ///@notice This function allow people to open their bid.
    function open(uint _value, bytes32 _nonce) public duringOpening {
        // Control the correctness of the bid
        // Update the bid status
        require(_value <= ReserveFund);
        require(chooses[msg.sender] == true);
        require(sha256(abi.encodePacked(_value, _nonce)) == bids[msg.sender].hash);
        bids[msg.sender].value = _value;
        bids[msg.sender].nonce = _nonce;
        if (firstOpen == true) {
            lowestBid = _value;
            lowestBidder = msg.sender;
            firstOpen = false;
        }
        else {
            if (_value < lowestBid) {
                lowestBid = _value;
                lowestBidder = msg.sender;
            }
        }
    }

    ///@notice This function finalize and close the contract.
    function finalize() public onlyAdmin {
        require(phase == Phase.Opening);
        require(block.number > startPhaseBlock + opening_len);
        if (firstOpen == true) {
            description.admin.transfer(ReserveFund);
            description.winnerAddress = address(0);
            description.winnerBid = 0;
        }
        else {
            lowestBidder.transfer(lowestBid);
            description.admin.transfer(ReserveFund - lowestBid);
            description.winnerAddress = lowestBidder;
            description.winnerBid = lowestBid;
        }
        emit auctionFinished(description.winnerAddress, description.winnerBid);
    }
}