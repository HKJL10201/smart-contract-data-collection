// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
* @title AuctionCampaign
* @dev This contract demonstrates the basic functionality of a AuctionCampaign contract
* @author _SteveJaySern
*/
contract AuctionCampaign {
    struct Auction {
        address owner;
        string title;
        string description;
        uint256 deadline;
        string image;
        uint256 currentBid;
        uint256 target;
        address winner;
        Participant[] participant;
    }

    struct Participant {
        address bidder;
        uint256 bidRecords;
        bool withdrawnStatus;
    }

    /**
    * @dev Mapping to store Auction state variable
    *      this allows client to retrieve specific auctions
    *      information by providing the auction 'key'
    */
    mapping(uint256 => Auction) public auctions;

    uint256 public numberOfAuctions = 0;

    /**
    * @dev Create an auction
    * @param _owner owner address.
    * @param _title auction title.
    * @param _description auction description.
    * @param _deadline auction deadline.
    * @param _image auction asset image.
    * @param _target bid target.
    * @return _return the total numberOfAuction (non-indexed).
    * @notice [1]: provide latest index auction and store in the reference of Auction struct variable.
    * @notice [2]: check if the deadline is some time in future.
    * @notice status: completed.
    */
    function createAuction(address _owner, string memory _title, string memory _description, uint256 _deadline,
    string memory _image, uint256 _target) public returns (uint256) {
        // [1]
        Auction storage auction = auctions[numberOfAuctions];
        // [2]
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        auction.owner = _owner;
        auction.title = _title;
        auction.description = _description;
        auction.deadline = _deadline;
        auction.image = _image;
        auction.currentBid = 0;
        auction.target = _target;
        auction.winner = address(0);

        // Initialize an empty array for participants in the auctionParticipants mapping
        numberOfAuctions++;
        return numberOfAuctions - 1;
    }

    /**
    * @dev Bid an auction
    * @param _id auction id.
    * @notice [1]: msg.value is a member of message object when sending (state transitioning
    *              transactions on the Ethereum network).
    * @notice [2]: get bid amount and bidder address, stores the value in selected
    *              Auction state variable
    * @notice TODO: we need a logic to handle if the payment is made upon winner is determined
    */
    function bidTheAuction(uint256 _id) public payable {
        // [1],[2]
        require(msg.value > 0, "Bid amount must be greater than 0.");
        require(auctions[_id].deadline > block.timestamp, "auction is over");
        uint256 amount = msg.value;
        address bidderAddress = msg.sender;

        Auction storage auction = auctions[_id];

        auction.participant.push(Participant({
            bidder: bidderAddress,
            bidRecords: amount,
            withdrawnStatus: false
        }));

        sendTransactionToAuctioneer(_id);
    }

    /**
    * @dev Get participants
    * @param _id auction id.
    * @return Participant[] the all participants array of selected auction (map-key).
    */
    function getParticipants(uint256 _id) view public returns(Participant[] memory) {
        return auctions[_id].participant;
    }

    /**
    * @dev List all auctions regardless of in progress or terminated status
    * @return allAuctions the all auctions in this contract (non-indexed).
    * @notice [1]: create dynamic array based on the size given by numberOfAuctions value [{}, {}, {}, {}, {}].
    * @notice [2]: please understand this logic from chatGPT
    * @notice TODO: change getAuctions() to listAuctions() instead
    * @notice TODO: instead of using an intermediate variable Auction storage item = auctions[i];
                    you can directly copy the data as allAuctions[i] = auctions[i],
                    which is more concise and achieves the same result.
    */
    function getAuctions() public view returns (Auction[] memory) {
        // [1]
        Auction[] memory allAuctions = new Auction[](numberOfAuctions);
        // [2], TODO
        for(uint i = 0; i < numberOfAuctions; i++) {
            Auction storage item = auctions[i];
            allAuctions[i] = item;
        }
        return allAuctions;
    }

    /**
    * @dev Check auction deadline status
    * @return deadlineStatus the auction deadlineStatus in boolean type.
    * @notice [1]: if the deadline has not been met, return a message to the client.
    * @notice status: completed.
    */
    function isPastDeadline(uint256 auctionDeadline) public view returns (bool deadlineStatus) {
        // require(auctionDeadline < block.timestamp, "The auction is still on going.");
        return auctionDeadline < block.timestamp;
    }
    /**
    * @dev Send transaction to Auctioneer
    * @return isSent the transaction status in boolean type.
    * @notice [1]: if the deadline has not been met, return a message to the client.
    * @notice status: completed.
    */
    function sendTransactionToAuctioneer(uint256 _id) public payable returns (bool isSent) {
        Auction storage auction = auctions[_id];
        // get the last index of participant from the current auction
        // Participant[] storage participants = auctionParticipants[_id];
        uint256 lastBidAmount = auction.participant[auction.participant.length - 1].bidRecords;
        // always consider last bidder is the auction winner
        auction.winner = auction.participant[auction.participant.length - 1].bidder;

        // sending amount from participant to contract to auction owner
        (bool sent,) = payable(auction.owner).call{value: lastBidAmount}("");
        return sent;
    }

    modifier afterDeadline(uint _id) {
        require(block.timestamp >= auctions[_id].deadline, "The deadline has not been reached yet.");
        _;
    }

    function withdrawFunds(uint256 _id) public {
        Auction storage auction = auctions[_id];
        require(auction.winner != msg.sender, "You have won the auction. No bid is refund to winner");
        // 9999 is the indicator for no participant found, should be change to -1 in future
        require(findParticipant(_id) < 9999, "1) Only the auction participants can withdraw funds. 2) You have already withdrawn your bid");
        require(auction.participant.length > 0, "No bids were made for this auction.");
        // Refund the auctioneer with the last bid amount
        uint256 thisParticipant = findParticipant(_id);
        uint256 bidAmount = auction.participant[thisParticipant].bidRecords;
        (bool sent, ) = payable(auction.participant[thisParticipant].bidder).call{value: bidAmount}("");

        auction.participant[thisParticipant].withdrawnStatus = true;
    }

    // convert to javascript array.find() function in next time
    function isParticipant(uint256 _id) public view returns (bool) {
        Auction storage auction = auctions[_id];
        // Iterate through the participants array and check for a match with msg.sender
        for (uint256 i = 0; i < auction.participant.length; i++) {
            if (auction.participant[i].bidder == msg.sender) {
                return true; // Matching participant found
            }
        }
        return false; // No matching participant found
    }

    //TODO change the return from `9999` to `-1` in future then change related uint256 to int256
    function findParticipant(uint256 _id) public view returns (uint256) {
        Auction storage auction = auctions[_id];

        for (uint256 i = 0; i < auction.participant.length; i++) {
            if (auction.participant[i].bidder == msg.sender) {
                return i; // Matching participant found
            }
        }
        return 9999;
    }
}