// SPDX-License-Identifier: GPL-3.0
//pragma solidity >=0.5.0 < 0.8.0;
pragma solidity >=0.5.0 < 0.9.0;

contract Lottery{

    address private manager;
    address payable[] private players;
    address payable private winner;
    uint private collection;
    uint private lotteryAmount;
    uint private playerMinLimit;

    /*
        one who deploy the contact is set as manager of the contract.
    */
    constructor(){
        manager = msg.sender;
        setDefault();
    }

    function setDefault() private{
        lotteryAmount = 3;
        playerMinLimit = 3;
        collection=0;
        players = new address payable[](0);
    }


    receive() external payable{
        require(msg.sender!=manager && msg.value==1 ether,"You are manager or transaction on !=1 Ether");

            players.push(payable(msg.sender));
            collection = collection+msg.value;
    }

    function random() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function selectWinner() public{
        require(msg.sender==manager && playerMinLimit<=players.length,"You are not manager or Minimum player not reached.");
        require( weiToEther(address(this).balance) >= lotteryAmount,"Lottery Amount is more the balance amount.");
        uint r = random();
        winner = players[r%players.length];
        winner.transfer(lotteryAmount*1000000000000000000);
        setDefault();
    }

    //Manager can set LotteryAmount to the winner.
    function setlotteryAmount(uint pa) public{
        require(msg.sender==manager,"You are not manager.");
        lotteryAmount = pa;
    }
    function getLotteryAmount() view public returns(uint){
        return lotteryAmount;
    }

    
    //Manager can set MinPlayerCount to the winner.
    function setMinPlayerCount(uint l) public{
        require(msg.sender==manager,"You are not manager.");
        playerMinLimit = l;
    }

    // Collection is the Ethers received from participants. 
    function getCollection() view public returns(uint){
        require(msg.sender==manager,"You are not manager.");
        return weiToEther(collection);
    }
    
    function LotteryRules() pure public returns(string memory){
        return "Participants must have wallet.";
        //	There Should be atleat 3 participants.
        //	Participants can tranfer ether more than once but the tranfered Ether must be 1 ether.
        //	As the participant will transfer Ether, its address will be registered.	Manager will have full control over Lottery.	The Lottery will be reset once a round is compeleted.";
    }

    function getParticipantCount() view public returns(uint){
        require(msg.sender==manager,"You are not manager.");
        return players.length;
    } 

    function getBalance() public view returns(uint){
        require(msg.sender==manager,"You are not manager.");
        return weiToEther(address(this).balance);
    } 

    // Convert WeiToEther
    function weiToEther(uint valueWei) pure private returns (uint)
    {
       return valueWei/(10**18);
    }

}