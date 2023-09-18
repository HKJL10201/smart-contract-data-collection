pragma solidity ^0.4.21;

import "./ierc20token.sol";

contract Pedersen {
    /* EIP-197 elliptic curve constants */ 
    uint public q =  21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint private gX = 19823850254741169819033785099293761935467223354323761392354670518001715552183;
    uint private gY = 15097907474011103550430959168661954736283086276546887690628027914974507414020;
    uint private hX = 3184834430741071145030522771540763108892281233703148152311693391954704539228;
    uint private hY = 1405615944858121891163559530323310827496899969303520166098610312148921359100;
    function Commit(uint b, uint r) public returns (uint cX, uint cY) {
        var (cX1, cY1) = ecMul(b, gX, gY);
        var (cX2, cY2) = ecMul(r, hX, hY);
        (cX, cY) = ecAdd(cX1, cY1, cX2, cY2);
    }
    function Verify(uint b, uint r, uint cX, uint cY) public returns (bool) {
        var (cX2, cY2) = Commit(b,r);
        return cX == cX2 && cY == cY2;
    }
    function CommitDelta(uint cX1, uint cY1, uint cX2, uint cY2) public returns (uint cX, uint cY) {
        (cX, cY) = ecAdd(cX1, cY1, cX2, q-cY2); // additively homomorphic
    }
    function ecMul(uint b, uint cX1, uint cY1) private returns (uint cX2, uint cY2) {
        bool success = false;
        bytes memory input = new bytes(96);
        bytes memory output = new bytes(64);
        assembly {
            mstore(add(input, 32), cX1)
            mstore(add(input, 64), cY1)
            mstore(add(input, 96), b)
            success := call(gas(), 7, 0, add(input, 32), 96, add(output, 32), 64)
            cX2 := mload(add(output, 32))
            cY2 := mload(add(output, 64))
        }
        require(success);
    }
    function ecAdd(uint cX1, uint cY1, uint cX2, uint cY2) public returns (uint cX3, uint cY3) {
        bool success = false;
        bytes memory input = new bytes(128);
        bytes memory output = new bytes(64);
        assembly {
            mstore(add(input, 32), cX1)
            mstore(add(input, 64), cY1)
            mstore(add(input, 96), cX2)
            mstore(add(input, 128), cY2)
            success := call(gas(), 6, 0, add(input, 32), 128, add(output, 32), 64)
            cX3 := mload(add(output, 32))
            cY3 := mload(add(output, 64))
        }
        require(success);
    }
}

contract VickreyAuction {
    enum AuctionState {Init, Bid, Finalize}
    struct Bidder {
        uint commitX;
        uint commitY;
        bytes cipher;
        bool validProofs;
        bool paidBack;
        bool existing;
    }
    struct ZKPCommit {
        address bidder;
        uint blockNumber;
        bytes cW1;
        bytes cW2;
    }
    Pedersen pedersen;
    bool withdrawLock;
    AuctionState public states;
    address seller;

    IERC20Token public token;
    uint256 public reservePrice;
    uint256 public endOfBidding;
    uint256 public endOfRevealing;

    address public highBidder;
    uint256 public highBid;
    uint256 public secondBid;

    mapping(address => bool) public revealed;
    address[] public bidderAddresses; //equivalent to indexs array in Galal code -- could probably get rid of this

    mapping(address => uint256) private balanceOf;
    mapping(address => bytes32) public commitXOf;
    mapping(address => bytes32) public commitYOf;

    function VickreyAuction(IERC20Token _token, uint256 _reservePrice, uint _bidBlockNumber, 
        uint _revealBlockNumber, uint _winnerPaymentBlockNumber,address _pedersenAddress) public {
        token = _token;
        reservePrice = _reservePrice;
        //initialize time intervals of the auction
        endOfBidding = block.number + _bidBlockNumber;
        endOfRevealing = endOfBidding + _revealBlockNumber;
        payWinners = endOfRevealing + _winnerPaymentBlockNumber;

        seller = msg.sender;
        highBidder = seller;
        highBid = reservePrice;
        secondBid = reservePrice;

        // the seller can't bid, but this simplifies withdrawal logic
        revealed[seller] = true;
        pedersen = Pedersen(pedersenAddress);
    }

    function transfer(address from, address to, uint256 amount) private {
        balanceOf[to] += amount;
        balanceOf[from] -= amount;
    }
    /* Submit a bid in the form of the Pedersen commitment */
    function bid(uint cX, uint cY) public payable {
        require(block.number < endOfBidding);
        require(msg.sender != seller);

        bidderAddresses.push(msg.sender);
        commitXOf[msg.sender] = cX;
        commitYOf[msg.sender] = cY;
        balanceOf[msg.sender] += msg.value; 
        require(balanceOf[msg.sender] >= reservePrice);
    }

    function reveal(uint256 b, uint256 r) public { 
        require(block.number >= endOfBidding && block.number < endOfRevealing);

        require(pedersen.Verify(_b, _r, commitXOf[msg.sender], commitYOf[msg.sender]));

        //bidders can only reveal once
        require(!revealed[msg.sender]);
        revealed[msg.sender] = true;

        if (b > balanceOf[msg.sender]) {
            // if there are insufficient funds to cover bid amount, ignore it
            return;
        }

        if (b >= highBid) { 
            // undo the previous escrow
            transfer(seller, highBidder, secondBid);

            // update the highest and second highest bids
            secondBid = highBid;
            highBid = b;
            highBidder = msg.sender;

            // escrow an amount equal to the second highest bid
            transfer(highBidder, seller, secondBid);
        } 

        else if (b > secondBid) {
            // undo the previous escrow
            transfer(seller, highBidder, secondBid);

            // update the second highest bid
            secondBid = b;

            // escrow an amount equal to the second highest bid
            transfer(highBidder, seller, secondBid);
       }
    }

    function withdraw() public {
        require(block.number >= endOfRevealing);
        require(revealed[msg.sender]);

        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function claim() public {
        require(block.number >= endOfRevealing);

        uint256 t = token.balanceOf(this);
        require(token.transfer(highBidder, t));
    }
}