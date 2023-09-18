pragma solidity ^0.4.17;

contract Auction {
    // Data
    // Item Data Structure
    struct Item {
        uint256 itemId;
        uint256[] itemTokens;
    }

    // Person Data Structure
    struct Person {
        uint256 remainingTokens;
        uint256 personId;
        address addr;
    }

    // Person
    // Sort of hashmap here.
    mapping(address => Person) tokenDetails; // Access person with his/her address
    Person[4] bidders; // 4 persons limited in the auction.

    // Item
    Item[3] public items;
    address[3] public winners; // Array that will save the winner per item
    address public beneficiary; // Owner of the smart contract

    uint256 bidderCount = 0; // Counter

    function Auction() public payable {
        // Part 1 Task 1. Initialize beneficiary with address of smart contract’s owner
        beneficiary = msg.sender;

        uint256[] memory emptyArray;

        items[0] = Item({itemId: 0, itemTokens: emptyArray});

        // Part 1 Task 2. Initialize two items with at index 1 and 2. 
        items[1] = Item({itemId: 1, itemTokens: emptyArray}); // items[1] = Item(1, emptyArray);
        items[2] = Item({itemId: 2, itemTokens: emptyArray});
    }

    function register() public payable {
        bidders[bidderCount].personId = bidderCount;
        // Part 1 Task 3. Initialize the address of the bidder 
        bidders[bidderCount].addr = msg.sender;

        bidders[bidderCount].remainingTokens = 5; // only 5 tokens
        tokenDetails[msg.sender] = bidders[bidderCount];
        bidderCount++;
    }

    // Part 2 Task 1. Create a modifier named "onlyOwner" to ensure that only owner is allowed to reveal winners
    // Hint : Use require to validate if "msg.sender" is equal to the "beneficiary".
    modifier onlyOwner() {
        // ** Start code here. 2 lines approximately. **
        require(msg.sender == beneficiary);
        _;
        //** End code here. **
    }

    function bid(uint256 _itemId, uint256 _count) public payable {
        /*
        Part 1 Task 4. Implement the three conditions below.
            4.1 If the number of tokens remaining with the bidder is < count of tokens bidded, revert.
            4.2 If there are no tokens remaining with the bidder, revert.
            4.3 If the id of the item for which bid is placed, is greater than 2, revert.

        Hint: "tokenDetails[msg.sender].remainingTokens" gives the details of the number of tokens remaining with the bidder.
        */
        if (
            tokenDetails[msg.sender].remainingTokens < _count ||
            tokenDetails[msg.sender].remainingTokens == 0 ||
            _itemId > 2
        ) {
            revert();
        }

        /*Part 1 Task 5. Decrement the remainingTokens by the number of tokens bid and store the value in balance variable.
        Hint. "tokenDetails[msg.sender].remainingTokens" should be decremented by "_count". */

        uint256 balance = tokenDetails[msg.sender].remainingTokens - _count;

        tokenDetails[msg.sender].remainingTokens = balance;
        bidders[tokenDetails[msg.sender].personId].remainingTokens = balance; //updating the same balance in bidders map.

        Item storage bidItem = items[_itemId];
        for (uint256 i = 0; i < _count; i++) {
            bidItem.itemTokens.push(tokenDetails[msg.sender].personId);
        }
    }

    function revealWinners() public onlyOwner {
        /* 
            Iterate over all the items present in the auction.
            If at least on person has placed a bid, randomly select          the winner */

        for (uint256 id = 0; id < 3; id++) {
            Item storage currentItem = items[id];
            if (currentItem.itemTokens.length != 0) {
                // generate random# from block number
                uint256 randomIndex = (block.number /
                    currentItem.itemTokens.length) %
                    currentItem.itemTokens.length;
                // Obtain the winning tokenId

                uint256 winnerId = currentItem.itemTokens[randomIndex];

                /* Part 1 Task 6. Assign the winners.
            Hint." bidders[winnerId] " will give you the person object with the winnerId.
            you need to assign the address of the person obtained above to winners[id] */

                // ** Start coding here *** 1 line approximately.
                winners[id] = bidders[winnerId].addr;
                //** end code here*
            }
        }
    }

     //Miscellaneous methods: Below methods are used to assist Grading. Please DONOT CHANGE THEM.
    function getPersonDetails(uint id) public constant returns(uint,uint,address){
        return (bidders[id].remainingTokens,bidders[id].personId,bidders[id].addr);
    }
}
