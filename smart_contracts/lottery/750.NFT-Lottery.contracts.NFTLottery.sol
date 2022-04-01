//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * FOR DEVS USING THIS CONTRACT:
 * - Replace all VRF-related parameters (vrfSubscriptionId, vrfCoordinator, keyHash, etc..) with your own keys (https://vrf.chain.link/)
 * - Set the TICKET_CAP, COMMUNITY_TICKET_CAP, and WINNER_TAKE_HOME_PERCENTAGE to whatever you see fit
 * - The tokenURI parameter should link to a metadata file hosted somewhere with the same format as ../nft-metadat.json
 * - Enjoy!
 */

contract NFTLottery is ERC721URIStorage, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds; // iterator for ticket ids
    Counters.Counter private _communityTicketCount; // iterator for vouchers given

    uint256 TICKET_CAP = 10; // maximum tickets to be sold
    uint256 COMMUNITY_TICKET_CAP = 4; // maximum tickets that can be given to the community
    uint256 MAX_TICKET_PURCHASE_SIZE = 100; // maximum tickets that can be given to the community
    uint256 TICKET_PRICE = 1000000000000000; // maximum tickets that can be given to the community
    uint256 WINNER_TAKE_HOME_PERCENTAGE = 95; // the percentage of the pot the winner gets (should be 0-100)
    mapping(address => uint256[]) ticketMapping; // an index mapping of each ticket owner address to its tickets

    uint256 public winningTicketId; // winning ticket

    VRFCoordinatorV2Interface COORDINATOR; // the interface by which VRF calls are made
    uint64 vrfSubscriptionId = 437; // subscription id for VRF call
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // chainlink vrf coordinator address
    uint32 callbackGasLimit = 100000; // gas limit for VRF call
    uint16 requestConfirmations = 3; // number of network confirmations needed for VRF
    uint32 vrfNumWords = 1; // number of random words to be requested
    bytes32 keyHash; // key hash for VRF call

    /**
     * @dev NFTLottery extends the ERC721 & VRFConsumerBase contracts
     */
    constructor()
        Ownable()
        ERC721("NFTLottery", "LOTTO")
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    }

    /**
     * @dev Verifies that the tickets are not sold out, or that the current order
     * would exceed the available ticket count.
     */
    modifier ticketsAreNotSoldOut(uint256 ticketQuantity) {
        uint256 ticketCount = _tokenIds.current();
        require(ticketCount < TICKET_CAP, "Tickets are sold out.");
        require(
            ticketCount + ticketQuantity <= TICKET_CAP,
            "This many tickets do not remain."
        );
        _;
    }

    /**
     * @dev Verifies that the community tickets have not all been distributed, or that the current order
     * would exceed the available community ticket count.
     */
    modifier communityTicketsStillRemain(uint256 ticketQuantity) {
        uint256 ticketCount = _communityTicketCount.current();
        require(
            ticketCount < COMMUNITY_TICKET_CAP,
            "Community tickets have already been distributed."
        );
        require(
            ticketCount + ticketQuantity <= COMMUNITY_TICKET_CAP,
            "This many community tickets do not remain."
        );
        _;
    }

    /**
     * @dev Verifies that the buyer is not purchasing too many tickets at once.
     */
    modifier ticketQuantityIsValid(uint256 ticketQuantity) {
        require(
            ticketQuantity <= MAX_TICKET_PURCHASE_SIZE,
            "Tickets are sold out."
        );
        _;
    }

    /**
     * @dev Mints a sepcified number of tickets for the user. A fee is collected and tokens are minted.
     * @param tokenURI the uri of metadata to be attached to the nft (user is free to customize this)
     * @param ticketQuantity the number of tickets to be purchased
     */
    function mintTicket(string memory tokenURI, uint256 ticketQuantity)
        public
        payable
        ticketsAreNotSoldOut(ticketQuantity)
        ticketQuantityIsValid(ticketQuantity)
    {
        require(
            msg.value >= TICKET_PRICE * ticketQuantity,
            "Insufficient funds."
        );

        for (uint256 i = 0; i < ticketQuantity; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();

            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, tokenURI);

            ticketMapping[msg.sender].push(newItemId);
        }
    }

    /**
     * @dev Mints tickets as a community grant to an address
     * @param recipient the recipient address of the ticket mint
     * @param tokenURI the uri of metadata to be attached to the nft (user is free to customize this)
     * @param ticketQuantity the number of tickets to be purchased
     */
    function mintTicketsForCommunityMember(
        address recipient,
        string memory tokenURI,
        uint256 ticketQuantity
    )
        public
        onlyOwner
        ticketsAreNotSoldOut(ticketQuantity)
        communityTicketsStillRemain(ticketQuantity)
        ticketQuantityIsValid(ticketQuantity)
    {
        for (uint256 i = 0; i < ticketQuantity; i++) {
            _tokenIds.increment();
            _communityTicketCount.increment();
            uint256 newItemId = _tokenIds.current();

            _mint(recipient, newItemId);
            _setTokenURI(newItemId, tokenURI);

            ticketMapping[recipient].push(newItemId);
        }
    }

    /**
     * @dev Mints tickets as a community grant to a set of addresses, each receiving one ticket
     * @param recipients the recipient addresses of the ticket mint
     * @param tokenURI the uri of metadata to be attached to the nft (user is free to customize this)
     */
    function mintTicketForCommunityMembers(
        address[] memory recipients,
        string memory tokenURI
    )
        public
        onlyOwner
        ticketsAreNotSoldOut(recipients.length)
        communityTicketsStillRemain(recipients.length)
        ticketQuantityIsValid(recipients.length)
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            _tokenIds.increment();
            _communityTicketCount.increment();
            uint256 newItemId = _tokenIds.current();

            _mint(recipients[i], newItemId);
            _setTokenURI(newItemId, tokenURI);

            ticketMapping[recipients[i]].push(newItemId);
        }
    }

    /**
     * @dev Gets the owner of a ticket.
     * @param ticketId the id of the ticket
     * @return the owning address of a ticket
     */
    function getHolderForTicketId(uint256 ticketId)
        public
        view
        returns (address)
    {
        return ownerOf(ticketId);
    }

    /**
     * @dev Gets the tickets an address owns.
     * @param adr the address of the ticket holder
     * @return tickets an address owns
     */
    function getTicketsForAddress(address adr)
        public
        view
        returns (uint256[] memory)
    {
        return ticketMapping[adr];
    }

    /**
     * @dev Gets the total number of tickets sold.
     * @return total tickets sold
     */
    function getTotalTicketsSold() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Gets the total pool size of the contract.
     * @return balance of the contract
     */
    function getPoolSize() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get random number from chainlink to assign as the winning ticket id.
     * @return the id of the chainlink vrf request
     */
    function generateWinningTicket() public onlyOwner returns (uint256) {
        require(
            winningTicketId == 0,
            "Winning ticket id has already been set."
        );
        uint256 resultId = COORDINATOR.requestRandomWords(
            keyHash,
            vrfSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            vrfNumWords
        );
        return resultId;
    }

    /**
     * @dev Allows chainlink to populate the winning ticket id with a tamper-proof random number.
     * @param randomWords the tamper-proof random numbers
     */
    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        winningTicketId = (randomWords[0] % _tokenIds.current()) + 1;
    }

    /**
     * @dev Gets the winning ticket id.
     * @return the winning ticket id
     */
    function getWinningTicketId() public view returns (uint256) {
        return winningTicketId;
    }

    /**
     * @dev Gets the owner of the winning ticket.
     * @return the address that owns the winning ticket
     */
    function getWinningAddress() public view returns (address) {
        return ownerOf(winningTicketId);
    }

    /**
     * @dev Pays out the winner, then self destructs the contract,
     * sending the rest of the contract balance to the contract owner.
     */
    function cashOutWinnings() public onlyOwner {
        require(
            winningTicketId != 0,
            "There has not been a winning ticket declared."
        );

        address payable winningAddress = payable(getWinningAddress());

        uint256 currentBalance = address(this).balance;
        uint256 winnerPayout = (currentBalance * WINNER_TAKE_HOME_PERCENTAGE) / 100;

        (bool sent, ) = winningAddress.call{value: winnerPayout}("");
        require(sent, "Failed to send Ether.");

        selfdestruct(payable(owner()));
    }
}
