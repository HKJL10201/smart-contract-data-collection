// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**@dev Store information of a lottery time
 *players of this time receive one token of this
 */
contract TicketNFT is Ownable, ERC721, ReentrancyGuard {
    using SafeMath for uint256;
    //is this lottery time ended
    bool public ended;
    //ticket max number
    uint8 private ticketSize;
    //ticket result this time
    uint8 public result;

    //order of lottery
    uint256 public lotteryTime;

    //current id of token
    uint256 public tokenId;

    //number of winners
    uint256 public winnersCount;

    //prize per winner
    uint256 public prize;

    //Player information
    struct Player {
        address wallet;
        uint8 ticket;
        bool isWinner;
    }

    //mapping tokenId to Player
    mapping(uint256 => Player) public idToPlayer;
    //mapping address to tokenId
    mapping(address => uint256) public addressToId;
    //mapping winner to tokenId
    mapping(uint256 => uint256) public winnersMapId;

    modifier notEnded() {
        require(!ended);
        _;
    }

    constructor(uint256 _times) ERC721("NDTLottery", "NDT") Ownable() {
        ticketSize = 5;
        lotteryTime = _times;
    }

    /**@dev create new player and mint token to player's address
     *call when a player buy a ticket
     */
    function mint(address _playerAddress, uint8 ticket)
        external
        onlyOwner
        nonReentrant
        notEnded
    {
        require(!hasPlayed(_playerAddress));
        require(_playerAddress != address(0));
        require(ticket < ticketSize);

        tokenId = tokenId.add(1);
        idToPlayer[tokenId] = Player(_playerAddress, ticket, false);
        addressToId[_playerAddress] = tokenId;

        _safeMint(_playerAddress, tokenId);
    }

    /**@return return ticket number of an address
     *return ticket size if that address haven't bought a ticket this time
     */
    function getTicketByAddress(address _address)
        external
        view
        returns (uint8)
    {
        if (hasPlayed(_address)) {
            return idToPlayer[addressToId[_address]].ticket;
        }
        return ticketSize;
    }

    /**@return true if a address has played this time */
    function hasPlayed(address _address) public view returns (bool) {
        if (idToPlayer[addressToId[_address]].wallet != address(0)) {
            return true;
        }
        return false;
    }
    /**@dev set result for this time */
    function setResult(uint8 _result)
        external
        notEnded
        onlyOwner
        returns (uint256)
    {
        result = _result;
        processPrize();
        return winnersCount;
    }
    /**@dev process the winners of this time */
    function processPrize() internal notEnded {
        if (tokenId > 0) {
            for (uint256 i = 1; i <= tokenId; i = i.add(1)) {
                if (idToPlayer[i].ticket == result) {
                    winnersCount = winnersCount.add(1);
                    idToPlayer[i].isWinner = true;
                    winnersMapId[winnersCount] = i;
                }
            }
        }
        ended = true;
    }

    /**@dev set prize number of this time
    *call when ended
    */
    function setPrize(uint256 _prize) external onlyOwner {
        require(ended == true);
        prize = _prize;
    }
    /**@return address of winner by winner index */
    function getWinnerAddressByIndex(uint256 _index)
        external
        view
        returns (address)
    {
        return idToPlayer[winnersMapId[_index]].wallet;
    }
}
