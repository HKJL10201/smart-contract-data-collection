//Author: Lucas Massoni Sguerra
//Institution: CRI - MINES ParisTech
//contact: lucas.sguerra@mines-paristech.fr

pragma solidity >=0.7.0 <0.8.2;

//Contract owned, from which VCG will inherit ownership, a basic access
//control mechanism
contract Owned {
    address public owner;

    constructor() {
        //setting owner as the contract deployer
        owner = msg.sender;
    }

    //modifier that only allows the owner address to call certain functions
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

//VCG contract inheriting ownership from owned contract
contract VCGSep is Owned {
    //Flag to signalize if an auction is underway
    bool public isOpen;
    //auctions click-through rate values
    uint256[] public ctrs;
    //bids values
    uint256[] public bids;
    //bidders' addresses
    address[] public agents;
    //struct for payment
    struct Price {
        uint256 price;
        bool payed;
    }
    //mapping from winners to prices
    mapping(address => Price) internal winnersAndPrices;

    //Events
    //Event emmited when an auction is opened, broadcasting the ctrs
    event Open(uint256[] ctrs);
    //Event emmited when an auction is ended, broadcasting winner agents and corresponding prices
    event EndAuction(address[] agents, uint256[] prices);

    //Constructior, set owner and isOpen as false
    constructor() {
        isOpen = false;
    }

    //Function open auction, updating the ctr values
    function openAuction(uint256[] calldata newCTRs) external onlyOwner {
        require(!isOpen, "Ongoing auction");
        isOpen = true;
        //delete winnersAndPrices;
        deleteMap();
        delete bids;
        delete agents;
        ctrs = newCTRs;
        emit Open(ctrs);
    }

    //Function for bidding, stores the bidder's address and bid value
    function bid(uint256 amount) external returns (uint256 numberOfBids) {
        require(isOpen, "Auction not open yet");
        bids.push(amount);
        agents.push(msg.sender);
        return bids.length;
    }

    //Function for closing auction
    //sort bids and calculate winners and corresponding prices
    //though doesn't record the winner values
    function closeAuction() external view onlyOwner returns (uint256[] memory results, uint256[] memory winnerIndexes) {
        require(isOpen, "Auction not open yet");
        require(bids.length > 0, "No bids to be auctioned");
        uint256 length = bids.length;
        uint256[] memory data = bids;
        uint256[] memory labels = new uint256[](length);

        for (uint256 j = 0; j < length; j++) {
            labels[j] = j;
        }

        for (uint256 j = 0; j < length; j++) {
            uint256 i = j;

            while ((i > 0) && (data[i] >= data[i - 1])) {
                swap(i, data, labels);
                i--;
            }
        }

        uint256[] memory result = new uint256[](ctrs.length);

        //calculate price
        for (uint256 i = 0; (i < ctrs.length && i < bids.length); i++) {
            uint256 price_i = 0;

            for (uint256 j = (i + 1); j < (ctrs.length + 1); j++) {
                price_i = price_i + (bids[labels[j]] * (getElement(ctrs, j - 1) - getElement(ctrs, j)));
            }
            result[i] = price_i;
        }

        return (result, labels);
    }

    //Function to cancel auction and reset parameters
    function cancelAuction() external onlyOwner {
        require(isOpen, "No ongoing auction");
        isOpen = false;
        if (bids.length > 0) {
            delete bids;
            deleteMap();
            delete agents;
            delete ctrs;
        }
    }

    function payment() external payable {
        require(!isOpen, "Ongoing auction");
        //require address in list
        require(winnersAndPrices[msg.sender].price != 0, "not a winner");
        //require payment equal to map
        require(msg.value == winnersAndPrices[msg.sender].price, "not enought money");
        winnersAndPrices[msg.sender].payed = true;
    }

    //function for the auctioneer to publish the auction results
    function publishResults(uint256[] calldata winnersIndex, uint256[] calldata prices) external onlyOwner {
        require(isOpen, "Auction still closed");
        require(bids.length > 0, "No bids stored");
        require(winnersIndex.length == prices.length, "insufficient data");
        isOpen = false;
        for (uint256 i = 0; i < winnersIndex.length; i++) {
            winnersAndPrices[agents[winnersIndex[i]]] = Price({price: prices[i], payed: false}); //prices[i];
        }
    }

    //Swap the positions of two elemements in the data and //labels table, part of the insert sort of closeAuction
    function swap(
        uint256 i,
        uint256[] memory data,
        uint256[] memory labels
    ) internal pure {
        uint256 tempData = data[i];
        uint256 tempLabels = labels[i];
        data[i] = data[i - 1];
        labels[i] = labels[i - 1];
        data[i - 1] = tempData;
        labels[i - 1] = tempLabels;
    }

    //Get element from list at position i
    //if there isn't an element, returns zero
    function getElement(uint256[] storage list, uint256 i) internal view returns (uint256 value) {
        if (i < list.length) return list[i];
        else return 0;
    }

    function deleteMap() internal {
        for (uint256 i = 0; i < agents.length; i++) {
            delete winnersAndPrices[agents[i]];
        }
    }
}

