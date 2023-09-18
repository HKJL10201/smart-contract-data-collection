// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "hardhat/console.sol";

contract Swap is Ownable, Pausable, IERC721Receiver, IERC1155Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private SwapId;

    // Current State of the swap
    enum SwapState { Created, Accepted, Cancelled }   

    // Wallet including ETH balance
    struct Entity {
        address addr;
        uint256 balance;
    }

    struct SwapItem {
        address tokenContract;      // Address to token contract
        string tokenType;          // ERC20, ERC721, ERC1155
        uint256[] tokenIds;         // TokenIds to transfer
        uint256 amount;             // If token is ERC20 token
        uint256[] amounts;          // If token is ERC1155 token
        bytes data;
    }

    struct SwapData {
        uint256 swapId;             // Unique Swap Id - only assigned using Counter
        uint256 createdTimestamp;   // Timestamp of Swap Creation
        uint256 executedTimestamp;  // Timestamp of Swap Execution (Cancelled or Accepted)

        Entity initiator;           // Swap Initiator
        Entity recipient;           // Swap Recipient

        SwapState state;            // State of current Swap, see SwapState definition
    }

    mapping(uint256 => SwapItem[]) offers;      // Offered Tokens mapped to SwapId
    mapping(uint256 => SwapItem[]) recieves;   // Requested Tokens mapped to SwapId
    mapping(uint256 => SwapData) swaps;         // Swap Data mapped to SwapId
    mapping(address => uint256[]) userSwaps;    // Address mapped to SwapIds

    // Events
    event SwapEvent(uint256 _id, address indexed _initiator, address _recipient, SwapState indexed _state, uint256 indexed _timestamp);

    constructor () { }

    modifier validSwap(uint256 _swapId) {
        require(_swapId < SwapId.current(), "Invalid SwapId provided");
        _;
    }

    modifier openSwap(uint256 _swapId) {
        require(swaps[_swapId].state == SwapState.Created, "Invalid Swap State");
        _;
    }

    function create (SwapItem[] memory _offer, SwapItem[] memory _retrieve, address _recipient) public whenNotPaused() {
        require(_offer.length != 0 && _retrieve.length != 0, "You have to either retrieve or offer a token");

        for (uint i = 0; i < _retrieve.length; i++) {
            require(_retrieve[i].tokenType == "ERC20" || 
                    _retrieve[i].tokenType == "ERC721" || 
                    _retrieve[i].tokenType == "ERC1155", "Invalid Tokens selected for retrieval");
        }

        // Create a new Swap
        SwapData memory swap = SwapData({
                swapId: SwapId.current(),
                createdTimestamp: block.timestamp,
                executedTimestamp: 0,
                initiator: Entity(msg.sender, msg.sender.balance),
                recipient: Entity(_recipient, 0),
                state: SwapState.Created
        });

        swaps[swap.swapId] = swap;
        
        for (uint256 i = 0; i < _offer.length; i++) {
            offers[swap.swapId].push(_offer[i]);
        }

        for (uint256 i = 0; i < _retrieve.length; i++) {
            recieves[swap.swapId].push(_retrieve[i]);
        }

        userSwaps[msg.sender].push(swap.swapId);

        SwapId.increment();

        // Collect offer tokens and store in contract:
        for (uint i = 0; i < _offer.length; i++) {
            transfer(msg.sender, address(this), _offer[i]);
        }

        emit SwapEvent(swap.swapId, swap.initiator.addr, swap.recipient.addr, SwapState.Created, swap.createdTimestamp);
    }

    function accept (uint256 _swapId) validSwap(_swapId) openSwap(_swapId) public whenNotPaused() {
        Entity memory initiator = swaps[_swapId].initiator;
        Entity memory recipient = swaps[_swapId].recipient;

        require(msg.sender == recipient.addr, "Function can only be called by the swap recipient");

        // Mark trade as successful
        uint256 executedTimestamp = block.timestamp;
        swaps[_swapId].executedTimestamp = executedTimestamp;
        swaps[_swapId].state = SwapState.Accepted;

        // Collect from recipient
        for (uint i = 0; i < recieves[_swapId].length; i++) {
            transfer(msg.sender, initiator.addr, recieves[_swapId][i]);
        }

        for (uint i = 0; i < offers[_swapId].length; i++) {
            transfer(address(this), recipient.addr, offers[_swapId][i]);
        }

        emit SwapEvent(_swapId, initiator.addr, recipient.addr, SwapState.Accepted, executedTimestamp);
    }

    function cancel (uint256 _swapId) validSwap(_swapId) openSwap(_swapId) public {
        Entity memory initiator = swaps[_swapId].initiator;
        Entity memory recipient = swaps[_swapId].recipient;

        require(msg.sender == initiator.addr || msg.sender == recipient.addr, "Function can only be called by the swap recipient or initiator");
        
        // Mark trade as cancelled
        uint256 executedTimestamp = block.timestamp;
        swaps[_swapId].executedTimestamp = executedTimestamp;
        swaps[_swapId].state = SwapState.Cancelled; 

        // Return the initiator's tokens
        for (uint i = 0; i < offers[_swapId].length; i++) {
            transfer(address(this), swaps[_swapId].initiator.addr, offers[_swapId][i]);
        }

       emit SwapEvent(_swapId, initiator.addr, recipient.addr, SwapState.Cancelled, executedTimestamp);
    }

    function getSwapIds (address _creator) public view returns (uint256[] memory) {
        return userSwaps[_creator];
    }

    function getSwap (uint256 _swapId) validSwap(_swapId) public view returns (SwapData memory) {
        return swaps[_swapId];
    }

    function getSwapItems (uint256 _swapId) validSwap(_swapId) public view returns (SwapItem[] memory offer, SwapItem[] memory recieve) {
        require(swaps[_swapId].initiator.addr == msg.sender, "You didn't create this swap");

        offer = offers[_swapId];
        recieve = recieves[_swapId];

        return (offer, recieve);
    }

    function transfer (address _from, address _to, SwapItem memory item) internal {
        if (item.tokenType == "ERC20") {
            transferERC20(_from, _to, item.tokenContract, item.amount);
        } else if (item.tokenType == "ERC721") {
            for (uint i = 0; i < item.tokenIds.length; i++) {
                transferERC721(_from, _to, item.tokenContract, item.tokenIds[i]);
            }
        } else if (item.tokenType == "ERC1155") {
            transferERC1155(_from, _to, item.tokenContract, item.tokenIds, item.amounts, item.data);
        }
    }

    function transferERC20 (address _from, address _to, address _token, uint256 _amount) internal {
        if (address(this) == _from) {
            IERC20(_token).transfer(_to, _amount);
        } 
        else {
            IERC20(_token).transferFrom(_from, _to, _amount);
        }
    }

    function transferERC721 (address _from, address _to, address _token, uint256 _tokenId) internal {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
    }

    function transferERC1155 (address _from, address _to, address _token, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) internal {
        IERC1155(_token).safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return  interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
    }
}


