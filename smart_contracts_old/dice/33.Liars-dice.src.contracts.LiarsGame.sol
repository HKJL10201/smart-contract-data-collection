pragma solidity ^0.5.0;

contract LiarsGame {
/*
    Liar's dice is a class of dice games for two or more players requiring the ability to deceive and to detect an opponent's deception.

In "single hand" liar's dice games, each player has a set of dice, all players roll once, and the bids relate to the dice each player can see (their hand) plus all the concealed dice (the other players' hands). In "common hand" games, there is one set of dice which is passed from player to player. The bids relate to the dice as they are in front of the bidder after selected dice have been re-rolled.

*/
    //Variable that stores total dice numbers of all users -> used during challenge
    uint256[] totalDiceQty = [0, 0, 0, 0, 0, 0];
    uint256 userCount = 0;
    uint256 currentTurn = 0;

    address[] addrList = new address[](5);
    struct diceList {
        uint256[] nums;
        uint256 size;
    }

    uint256 storedData = 0;

    function set(uint256 x) public {
        storedData = 0;
        storedData = x;
    }

    struct currentBid {
        uint256 num;
        uint256 qty;
        address addr;
    }

    currentBid cBid;

    function get() public view returns (uint256) {
        return storedData;
    }

    mapping(address => diceList) addressDiceMap;

    uint256 public joiningEnd;

    constructor(uint256 _joiningTime) public {
        joiningEnd = now + _joiningTime;
    }

    uint256 public nonce = 12345;

    //random number generator between 1 to 6 -> for dice allocation
    function random() private returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(now, msg.sender, nonce))
        ) % 6;
        randomnumber = randomnumber + 1;
        nonce++;
        return randomnumber;
    }

    /*
        Players need to join game by calling this function
    */
    function joinGame() public {
        //require(now <= joiningEnd, "Game Join period ended");
        // require(addressDiceMap[msg.sender].length == 0 , "Player already joined Game"); ?????/
        diceList memory initialList;

        // assigning 3 dices for eaxh player at the beginning of game
        initialList.size = 3;
        uint256[] memory nums = new uint256[](3);
        nums[0] = random();
        nums[1] = random();
        nums[2] = random();

        totalDiceQty[nums[0] - 1] = totalDiceQty[nums[0] - 1] + 1;
        totalDiceQty[nums[1] - 1] = totalDiceQty[nums[1] - 1] + 1;
        totalDiceQty[nums[2] - 1] = totalDiceQty[nums[2] - 1] + 1;
        initialList.nums = nums;
        addressDiceMap[msg.sender] = initialList;
        addrList[userCount] = msg.sender;
        userCount = userCount + 1;
    }
    /*
        returns list of dices each user is holding to the web app
    */
    function showDiceList() public view returns (address, uint256[] memory) {
        diceList storage dl = addressDiceMap[msg.sender];

        return (msg.sender, dl.nums);
    }

    /*
        returns total dices qty of each number 
    */
    function totalDiceList() public view returns (uint256[] memory) {
        return (totalDiceQty);
    }

    /*
        function to place bid
    */
    function bid(uint256 num, uint256 qty) public {
        currentBid storage cBID = cBid;
        cBID.num = num;
        cBID.qty = qty;
        cBID.addr = msg.sender;
        currentTurn=(currentTurn+1)%userCount;
    }
    /*
        function that send winner details during challenge
    */
    function winnerDetails() public view returns (address) {
        currentBid storage cBID = cBid;
        if (totalDiceQty[cBID.num - 1] >= cBID.qty) {
            return cBID.addr;
        } else {
            //remove dice from loser
            return msg.sender;
        }
    }
    /*
       function to place challenge
       find winner
       remove dice from loser

    */
    function challenge() public returns (address) {
        currentBid storage cBID = cBid;
        
        address addrs;
        if (totalDiceQty[cBID.num - 1] >= cBID.qty) {
            //remove dice from loser
            diceList storage dl = addressDiceMap[msg.sender];
            if (dl.size > 0) {
                dl.size = dl.size - 1;
            }
            //rollNewDice();
            //return winner address
            addrs = cBID.addr;
            //If challeger loses -- chance will goto next person
            currentTurn=(currentTurn+1)%userCount;
        } else {
            //remove dice from loser
            diceList storage dl = addressDiceMap[cBID.addr];
            if (dl.size > 0) {
                dl.size = dl.size - 1;
            }
            //rollNewDice();
            //return winner address
            addrs = msg.sender;
        }
        totalDiceQty = [0, 0, 0, 0, 0, 0];
        uint toDeleteUserIndex=100; //any number above max players
        for (uint256 i = 0; i < userCount; i++) {
            diceList storage dl = addressDiceMap[addrList[i]];

            if(dl.size>0){
            diceList memory initialList;
            initialList.size = dl.size;
            uint256[] memory nums = new uint256[](dl.size);
            for (uint256 j = 0; j < dl.size; j++) {
                nums[j] = random();
                totalDiceQty[nums[j] - 1] = totalDiceQty[nums[j] - 1] + 1;
            }
            initialList.nums = nums;
            addressDiceMap[addrList[i]] = initialList;
            }
            else{
                toDeleteUserIndex=i;
            }
        }
        /*
        if(toDeleteUserIndex!=100){
            if(currentTurn==toDeleteUserIndex){
                currentTurn=(currentTurn+1)%(userCount-1);
               // delete addrList[toDeleteUserIndex];
            }
        }
        */
        return addrs;
    }
    /*
        function that returns game data to web app continously
    */
    function getGameData()
        public
        view
        returns (
            uint256,
            uint256,
            address,
            address
        )
    {
        currentBid storage cBID = cBid;
        return (cBID.num, cBID.qty, cBid.addr,addrList[currentTurn]);
    }
}
