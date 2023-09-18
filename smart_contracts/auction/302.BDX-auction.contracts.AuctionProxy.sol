//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Types.sol";

/**
 *
 *       ,---,.     ,---,    ,--,     ,--,
 *     ,'  .'  \  .'  .' `\  |'. \   / .`|
 *   ,---.' .' |,---.'     \ ; \ `\ /' / ;
 *   |   |  |: ||   |  .`\  |`. \  /  / .'
 *   :   :  :  /:   : |  '  | \  \/  / ./
 *   :   |    ; |   ' '  ;  :  \  \.'  /
 *   |   :     \'   | ;  .  |   \  ;  ;
 *   |   |   . ||   | :  |  '  / \  \  \
 *   '   :  '; |'   : | /  ;  ;  /\  \  \
 *   |   |  | ; |   | '` ,/ ./__;  \  ;  \
 *   |   :   /  ;   :  .'   |   : / \  \  ;
 *   |   | ,'   |   ,.'     ;   |/   \  ' |
 *   `----'     '---'       `---'     `--`
 *  BDX Smart Contract
 */

interface IFactory {
    function implementation() external returns (address);
}

contract BigDataAuction is ReentrancyGuard {
    using Address for address;
    AuctionState public auctionState;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public price;
    //unit GiB: 1 TiB = 1024 GiB
    uint256 public size;
    int8 public version = 7;

    address[] public bidders;
    mapping(address => Bid) public bids;
    mapping(AuctionState => uint256) public times;

    address public admin;
    address public client;

    IEventBus private eventBus;
    IERC20 private paymentToken;
    address public offerManager;
    address public factory;

    string public metaUri;

    uint256[50] internal _gap;

    constructor(
        IERC20 _paymentToken,
        uint256 _price,
        uint256 _size,
        address _client,
        address _admin,
        uint256 _endTime,
        address _offerManager,
        address _eventBus,
        string memory _metaUri
    ) {
        admin = _admin;
        eventBus = IEventBus(_eventBus);
        metaUri = _metaUri;
        paymentToken = IERC20(_paymentToken);
        offerManager = _offerManager;
        price = _price;
        size = _size;
        auctionState = AuctionState.BIDDING;
        client = _client;
        startTime = block.timestamp;
        endTime = _endTime;
        factory = msg.sender;
    }

    function getImplemention() public returns (address) {
        address _addr = IFactory(factory).implementation();
        return _addr;
    }

    receive() external payable {
        _fallback();
    }

    fallback() external payable virtual {
        _fallback();
    }

    function _fallback() internal {
        _delegate(getImplemention());
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
