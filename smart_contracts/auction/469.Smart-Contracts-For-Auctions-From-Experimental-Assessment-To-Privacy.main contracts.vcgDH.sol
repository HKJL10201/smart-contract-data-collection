//Author: Lucas Massoni Sguerra
//Institution: CRI - MINES ParisTech
//contact: lucas.sguerra@mines-paristech.fr
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.2;

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

contract VCGDH is Owned {
    //different stages of the auction
    enum Stages {Close, Commit, Reveal, Payment}
    //Event emmited when the auction is over
    event EndAuction();

    modifier atStage(Stages _stage) {
        require(stage == _stage, "Wrong stage. Action not allowed.");
        _;
    }

    function nextStage() internal {
        stage = Stages(uint256(stage) + 1);
    }

    Stages public stage = Stages.Close; //start with a closed auction

    uint256[] public ctrs;
    bytes[] public encryptedBids;
    bytes32[] public hashedBids;
    address[] public agents;
    //mapping to keep track of bid
    mapping(address => uint256) public indexes;

    //struct for payment
    struct Price {
        uint256 price;
        bool payed;
    }
    //mapping from winners to prices
    mapping(uint256 => Price) internal winnersAndPrices;

    //Events
    //Event emmited when an auction is opened, broadcasting the ctrs
    event Open(uint256[] ctrs);

    constructor() {}

    function openAuction(uint256[] calldata newCTRs) external onlyOwner atStage(Stages.Close) {
        nextStage();
        //delete winnersAndPrices;
        deleteMap();
        delete hashedBids;
        delete encryptedBids;
        delete agents;
        ctrs = newCTRs;
        emit Open(ctrs);
    }

    function bid(bytes32 hashedBid) external atStage(Stages.Commit) {
        hashedBids.push(hashedBid);
        encryptedBids.push("0x0"); //start encryptedBids array
        agents.push(msg.sender);
        indexes[msg.sender] = agents.length - 1;
    }

    //View function that bidders can use to encrypt their bid
    function encryptBid(string calldata commit, bytes calldata key) external pure returns (bytes memory) {
        //one time pad
        bytes memory messageinBytes = abi.encode(commit);
        bytes memory messageinKey = abi.encode(key);
        bytes memory ciphertext = new bytes(messageinBytes.length);
        for (uint256 i; i < messageinBytes.length; i++) {
            ciphertext[i] = messageinBytes[i] ^ messageinKey[i];
        }
        return ciphertext;
    }

    function stopCommitPhase() external onlyOwner atStage(Stages.Commit) {
        nextStage();
    }

    function encryptedBidding(bytes calldata encryptedBid) external atStage(Stages.Reveal) {
        uint256 index = indexes[msg.sender];
        encryptedBids[index] = encryptedBid;
    }

    //view function to retrieve bids with the sahred key
    function retrieveAllBids(bytes calldata sharedKey) external view atStage(Stages.Reveal) returns (string[] memory) {
        string[] memory bidsPasswords = new string[](agents.length);

        for (uint256 i = 0; i < agents.length; i++) {
            bidsPasswords[i] = decrypt(encryptedBids[i], sharedKey);
        }
        return bidsPasswords;
    }

    function closeAuction(uint256[] calldata bids)
        external
        view
        atStage(Stages.Reveal)
        returns (uint256[] memory results, uint256[] memory winnerIndexes)
    {
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

        for (uint256 i = 0; (i < ctrs.length && i < bids.length); i++) {
            uint256 price_i = 0;
            for (uint256 j = (i + 1); j < (ctrs.length + 1); j++) {
                price_i = price_i + (bids[labels[j]] * (getElement(ctrs, j - 1) - getElement(ctrs, j)));
            }
            result[i] = price_i;
        }
        return (result, labels);
    }

    function publishResults(uint256[] calldata winnersIndex, uint256[] calldata prices)
        external
        onlyOwner
        atStage(Stages.Reveal)
    {
        nextStage();
        require(winnersIndex.length == prices.length, "insufficient data");
        for (uint256 i = 0; i < winnersIndex.length; i++) {
            winnersAndPrices[winnersIndex[i]] = Price({price: prices[i], payed: false}); //prices[i];
        }
        emit EndAuction();
    }

    function payment() external payable atStage(Stages.Payment) {
        uint256 index = indexes[msg.sender];
        require(winnersAndPrices[index].price != 0, "not a winner");
        require(msg.value == winnersAndPrices[index].price, "not enought money");
        winnersAndPrices[index].payed = true;
    }

    function cancelAuction() external {
        require(stage != Stages.Payment, "Cannot cancel ongoing auction");
        if (encryptedBids.length > 0) {
            delete encryptedBids;
            delete hashedBids;
            deleteMap();
            delete agents;
            delete ctrs;
        }
    }

    function calculateHash(uint256 bid, string calldata password) external view returns (bytes32) {
        return (keccak256(abi.encodePacked(bid, password, msg.sender)));
    }

    function decrypt(bytes memory message, bytes calldata key) public pure returns (string memory) {
        bytes memory plainText = new bytes(message.length);
        bytes memory messageinKey = abi.encode(key);
        for (uint256 i = 0; i < (message.length); i++) {
            plainText[i] = message[i] ^ messageinKey[i];
        }
        return abi.decode(plainText, (string));
    }

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

    function getElement(uint256[] storage list, uint256 i) internal view returns (uint256 value) {
        if (i < list.length) return list[i];
        else return 0;
    }

    function deleteMap() internal {
        for (uint256 i = 0; i < agents.length; i++) {
            delete winnersAndPrices[i];
        }
    }
}

