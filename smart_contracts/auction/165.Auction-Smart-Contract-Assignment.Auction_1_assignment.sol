pragma solidity ^0.4.17;

contract Auction {
    // Data Structure to hold details of the item
    struct Item {
        uint256 itemId; // id of the item
        uint256[] itemTokens; //tokens bid in favor of the item
    }

    //Structure to hold the details of a persons
    struct Person {
        uint256 remainingTokens; // tokens remaining with bidder
        uint256 personId; // it serves as tokenId as well
        address addr; //address of the bidder
    }

    mapping(address => Person) tokenDetails; //address to person
    Person[4] bidders; //Array containing 4 person objects

    Item[3] public items; //Array containing 3 item objects
    address[3] public winners; //Array for address of winners
    address public beneficiary; //owner of the smart contract

    uint256 bidderCount = 0; //counter

    // Logic
    function Auction() public payable {
        beneficiary = msg.sender;
        uint256[] memory emptyArray;
        items[0] = Item({itemId: 0, itemTokens: emptyArray});
        items[1] = Item({itemId: 1, itemTokens: emptyArray});
        items[2] = Item({itemId: 2, itemTokens: emptyArray});
    }

    function register() public payable {
        bidders[bidderCount].personId = bidderCount;
        bidders[bidderCount].addr = msg.sender;
        //** End code here. **

        bidders[bidderCount].remainingTokens = 5; // only 5 tokens
        tokenDetails[msg.sender] = bidders[bidderCount];
        bidderCount++;
    }

    function bid(uint256 _itemId, uint256 _count) public payable {
        if (
            tokenDetails[msg.sender].remainingTokens < _count ||
            tokenDetails[msg.sender].remainingTokens == 0
        ) revert();
        if (_itemId > 2) revert();

        tokenDetails[msg.sender].remainingTokens =
            tokenDetails[msg.sender].remainingTokens -
            _count;

        uint256 balance = tokenDetails[msg.sender].remainingTokens;

        tokenDetails[msg.sender].remainingTokens = balance;
        bidders[tokenDetails[msg.sender].personId].remainingTokens = balance; //updating the same balance in bidders map.

        Item storage bidItem = items[_itemId];
        for (uint256 i = 0; i < _count; i++) {
            bidItem.itemTokens.push(tokenDetails[msg.sender].personId);
        }
    }

    // Modifier for only owner can use it
    modifier onlyOwner() {
        _;
    }

    function revealWinners() public onlyOwner {
        for (uint256 id = 0; id < 3; id++) {
            Item storage currentItem = items[id];
            if (currentItem.itemTokens.length != 0) {
                // generate random# from block number
                uint256 randomIndex = (block.number /
                    currentItem.itemTokens.length) %
                    currentItem.itemTokens.length;

                // Obtain the winning tokenId
                uint256 winnerId = currentItem.itemTokens[randomIndex];
                winners[id] = bidders[winnerId].addr;
            }
        }
    }

    function getPersonDetails(uint256 id)
        public
        constant
        returns (
            uint256,
            uint256,
            address
        )
    {
        return (
            bidders[id].remainingTokens,
            bidders[id].personId,
            bidders[id].addr
        );
    }
}
