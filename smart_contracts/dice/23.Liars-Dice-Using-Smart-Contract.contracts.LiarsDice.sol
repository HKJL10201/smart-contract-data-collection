// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/*******************************************************************************
 * A brief history of Liars Dice.
 *
 * Liars dice game made using smart contracts. It starts with
 * a forward slash followed by some number, n, of asterisks, where n > 2. It's
 * written this way to be more "visible" to developers who are reading the
 * source code.
 *
 * Often, developers are unaware that this is not (by default) a valid Doxygen
 * comment block!
 *
 *
 * This style of commenting behaves well with clang-format.
 *
 * Even if there is only one possible unified theory. it is just a
 *               set of rules and equations.
 ******************************************************************************/

contract LiarsDice {
    uint256 public numPlayers  = 0;
    address payable[] public players = new address payable[](10);

    uint256 public turn;
    uint256[] private faceNumber = new uint256[](7);

    uint256 public bidFace;
    uint256 public bidQuantity;
    address payable public bidAddress;
    address payable public curBidder;

    mapping(address => bytes32) private hashedDice;
    address payable public challenger;
    uint256 public challengeState;
    uint256 public revealLeft;
    address payable public winner;
    address payable public loser;
    uint256 public winnerIndex;
    uint256 public quantity;
    bytes32 private baseHash;

    
    constructor() public {
        turn = 0;
        bidFace = 0;
        bidQuantity = 0;
        numPlayers = 0;
        baseHash = 0;
        faceNumber = [0, 0, 0, 0, 0, 0, 0];
	challengeState = 0;
    }

    /* 
      @notice function to register participant
    */
    function registerParticipant() public payable {
        players[numPlayers] = msg.sender;
        if (numPlayers == 0) curBidder = players[0];
        numPlayers++;
	challengeState = 0;
	bidFace = 0;
        bidQuantity = 0;
	//numPlayers = 0;
    }

    /*
      @notice function to hash the die
      @param Hash Value
    */
    function setDice(bytes32 h) public {
        hashedDice[msg.sender] = h;
    }
    
    /* 
      @notice function to make a bid
      @param bid face
      @param bid quantity
    */
    function makeBid(uint256 f, uint256 q) public {
        bidFace = f;
        bidQuantity = q;
        bidAddress = msg.sender;
        turn = (turn + 1) % numPlayers;
        curBidder = players[turn];
    }
    
    /* 
      @notice function to start the challenge phase
    */
    function initiateChallenge() public payable {
        challenger = msg.sender;
        challengeState = 1;
        // revealLeft = numPlayers;
        revealLeft = 4;
    }
    
    
    function revealDice(
        uint256 f1,
        uint256 f2,
        uint256 f3,
        uint256 f4,
        uint256 f5,
        uint256 nonce
    ) public {
        require(
            keccak256(abi.encodePacked(f1, f2, f3, f4, f5, nonce)) ==
                hashedDice[msg.sender],
            "Revealed Bid or Nonce don't match"
        );
        faceNumber[f1]++;
        faceNumber[f2]++;
        faceNumber[f3]++;
        faceNumber[f4]++;
        faceNumber[f5]++;
        revealLeft--;
        if (revealLeft == 0) {
            checkWin();
        }
    }
    /* 
      @notice function to check winning condition
    */
    function checkWin() public payable {
        quantity = faceNumber[bidFace];
        if (quantity >= bidQuantity) {
            winner = bidAddress;
            loser = challenger;
            winnerIndex = (turn == 0) ? numPlayers : turn;
        } else {
            winner = challenger;
            loser = bidAddress;
            winnerIndex = (turn + 1);
        }
        winner.transfer(4e18);
    }

    function claimReward() public payable{
        winner.transfer(4e18);

        // require(hashedDice[msg.sender] != baseHash, "kitni baar claim karega");
        // hashedDice[msg.sender] = baseHash;
        // numPlayers--;
        // if(numPlayers == 0){
        //     turn = 0;
        //     bidFace = 0;
        //     bidQuantity = 0;
        //     faceNumber = [0, 0, 0, 0, 0, 0, 0];
        // }
        // address payable toSend = msg.sender;
        // // require(msg.sender != loser, "You lost, you will not receive even a single penny !");
        // if(msg.sender == winner){
        //     toSend.transfer(4e18);
        // }
        // else{
        //     toSend.transfer(2e18);
        // }
    }

    function getAllPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
