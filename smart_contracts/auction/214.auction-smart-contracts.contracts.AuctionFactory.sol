// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import './Auction.sol';

/**
 * @title AuctionFactory
 * @author ggulaman
 * @notice Smart Contract (SC) which generates Auction SCs.
 * @dev TODO: 1. double check which functions should not be public | 2. Import the OpenZeppelin Owner SC | 3. OpenZeppelin maths | 4. Check Licences
 * @dev TODO: 5. Consider to destroy SC once they are completed | 6. Add OpenZeppelin Upgrade
 */
contract AuctionFactory {
    // EVENTS
    // event for Etherum Virtual Machine (EVM) logging the Owner of the SC (Smart Contract)
    event OwnerSet(address indexed oldOwner, address indexed newOwner); // Raised when new Owner defined
    event NewAuction(address indexed auctionAddress, string indexed ERC20Name); // Raised when new auction created


    // VARIABLES
    address owner;

    // Auction Structure. For now it could be an array, but we will add more fields in the future
    struct auctionStructure {
        string ERC20Name;
    }
    auctionStructure[] public auctionsList; // Array of auctionStructure with all the auction details 
    address[] public auctionsAddressList; // Array containg the address of each Auction SC

    /**
     * @dev Constructor only adds the owner of the Smart Contract
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @notice Returns the Number Of Auction SCs
     * @return the Lenght of auctionsAddressList, the array with the Auction SC addresses
     */
    function getNumberOfAuctions() public view returns(uint256) {
      return auctionsAddressList.length;
    }

    /**
     * @notice Creates an Auction SCs
     * @param _auctionDuration the time the auction last in seconds, _ERC20Name the name of the token, _ERC20Symbol the simbol of the token, _supply the total supply of the ERC20
     * @return the Id of the new Auction SC
     */
    function createANewAuction(uint256 _auctionDuration, string memory _ERC20Name, string memory _ERC20Symbol, uint256 _supply ) public returns (uint256) {
        require(owner == msg.sender, "only owner");
        auctionsList.push(auctionStructure({
                ERC20Name: _ERC20Name
        }));
        Auction auction = new Auction(msg.sender, _auctionDuration, _ERC20Name, _ERC20Symbol, _supply);
        auctionsAddressList.push(address(auction));
        uint256 auctionId = getNumberOfAuctions() + 1;
        emit NewAuction(address(auction), _ERC20Name);
        return auctionId - 1;
     }
}