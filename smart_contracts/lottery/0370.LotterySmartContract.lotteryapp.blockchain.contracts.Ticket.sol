// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Ticket is ERC721 {

    // Ticket number
    uint256 private ticketNo;
    // Ticket owner
    address private owner;
    // Hash of the random number held by the owner of this ticket
    bytes32 private hash_rnd_number;
    /* status:
    0 for purchased
    1 for cancelled
    2 for no longer owned
    3 for revealed correctly
    4 for prize collected
    */ 
    uint8 public status;
    // Lottery number of the lottery which this ticket is part of
    uint private lotteryNo;

    /**
    * @dev Constructor of the Ticket contract
    */
    constructor(uint256 _ticketNo, address _owner, bytes32 _hash_rnd_number, uint _lotteryNo) ERC721("Ticket", "TCK") {
        ticketNo = _ticketNo;
        hash_rnd_number = _hash_rnd_number;
        status = 0;
        owner = _owner;
        lotteryNo = _lotteryNo;
    }

    /**
    * @dev Returns the ticket number
    */
    function getTicketNo() public view returns (uint256) {
        return ticketNo;
    }

    /**
    * @dev Returns the hash of the random number
    */
    function getHash_rnd_number() public view returns (bytes32) {
        return hash_rnd_number;
    }

    /**
    * @dev Returns the owner address
    */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
    * @dev Returns the lottery number
    */
    function getLotteryNo() public view returns (uint) {
        return lotteryNo;
    }

    /**
    * @dev Sets the status of the ticket to the given status
    */
    function setStatus(uint8 _status) public {
        require(_status <= 4, "Status must be between 0 and 4 inclusive");
        status = _status;
    }
}