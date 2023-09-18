pragma solidity ^0.6.4;


contract Auction {
    //Data
    struct Item {
        uint256 itemId;
        uint256[] itemTokens;
    }

    struct Person {
        uint256 personId;
        uint256 remainingTokens;
        address addr;
    }

    mapping(address => Person) tokenDetails;
    Person[4] bidders;
    Item[3] public items;
    address[3] public winners;
    address public beneficiary; //owner of the smart contract
    uint256 bidderCount = 0;

    //functions
    constructor() public payable {
        beneficiary = msg.sender;
        uint256 n = 3;
        uint256[] memory emptyArray;
        for (uint256 i = 0; i < n; i++) {
            items[i] = Item({itemId: i, itemTokens: emptyArray});
        }
    }

    function register() public payable {
        bidders[bidderCount].personId = bidderCount;
        bidders[bidderCount].remainingTokens = 5; // only 5 tokens
        bidders[bidderCount].addr = msg.sender;
        tokenDetails[msg.sender] = bidders[bidderCount]; //mapping address to person

        bidderCount++;
    }

    function bid(uint256 _itemId, uint256 _count) public payable {
        if (_itemId > bidderCount) {
            revert('itemId not available');
        }
        if (
            tokenDetails[msg.sender].remainingTokens < _count ||
            tokenDetails[msg.sender].remainingTokens == 0
        ) {
            revert('Not enough tokens');
        }
        tokenDetails[msg.sender].remainingTokens -= _count;
        bidders[tokenDetails[msg.sender].personId]
            .remainingTokens = tokenDetails[msg.sender].remainingTokens;

        Item storage bidItem = items[_itemId];
        for (uint256 i = 0; i < _count; i++) {
            bidItem.itemTokens.push(tokenDetails[msg.sender].personId);
        }
    }

    modifier onlyOwner {
        require(beneficiary == msg.sender,'Only the owner could reveal the winners.');
        _;
    }

    function revealWinners() public onlyOwner {
        for (uint256 id = 0; id < 3; id++) {
            Item storage currentItem = items[id];
            if (currentItem.itemTokens.length != 0) {
                uint256 randomIndex = (block.number /
                    currentItem.itemTokens.length) %
                    currentItem.itemTokens.length;

                uint256 winnerId = currentItem.itemTokens[randomIndex];
                winners[id] = bidders[winnerId].addr;
            }
        }
    }

    function getPersonDetails(uint256 id)
        public
        view
        returns (uint256, uint256, address)
    {
        return (
            bidders[id].remainingTokens,
            bidders[id].personId,
            bidders[id].addr
        );
    }
}
