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
contract VCG is Owned {
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

    //Constructior, set isOpen as false
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
    function closeAuction() external onlyOwner returns (uint256[] memory Prices) {
        require(isOpen, "Auction not open yet");
        require(bids.length > 0, "No bids to be auctioned");

        isOpen = false;
        uint256 length = bids.length;
        uint256[] memory data = bids;
        uint256[] memory labels = bids;

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

        uint256[] memory result = calculatePrice(labels);

        return result;
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

    //Internal function to calculate winner's prices following VCG's algorithm
    function calculatePrice(uint256[] memory labels) internal returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](ctrs.length);
        for (uint256 i = 0; (i < ctrs.length && i < agents.length); i++) {
            uint256 price_i = 0;

            for (uint256 j = (i + 1); j < (ctrs.length + 1); j++) {
                price_i = price_i + (getElement(bids, labels[j]) * (getElement(ctrs, j - 1) - getElement(ctrs, j)));
            }
            prices[i] = (price_i);
        }
        address[] memory winners = new address[](ctrs.length);
        winners = agentsSlice(labels);
        emit EndAuction(winners, prices);

        for (uint256 i = 0; i < winners.length; i++) {
            winnersAndPrices[winners[i]] = Price({price: prices[i], payed: false}); //prices[i];
        }

        return prices;
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

    //Slices agrents array, to generate a winners table
    function agentsSlice(uint256[] memory labels) internal view returns (address[] memory winners) {
        winners = new address[](ctrs.length);
        if (ctrs.length < agents.length) {
            for (uint256 i = 0; i < ctrs.length; i++) {
                winners[i] = (agents[labels[i]]);
            }
            return winners;
        } else {
            return agents;
        }
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
