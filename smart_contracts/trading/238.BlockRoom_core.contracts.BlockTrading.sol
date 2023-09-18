// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IBlock.sol";
import "./interfaces/IBlockers.sol";
import "./interfaces/IBlockFeed.sol";
import "./interfaces/IBlockStorage.sol";
import "./libraries/feeCalculator.sol";
import "./interfaces/IBlockAddresses.sol";
import "./helpers/zeroAddressPreventer.sol";

/**
 * @title BlockTrading
 * @author javadyakuza
 * @notice this contract is used to trade the BLocks in the BlockRoom
 */
contract BlockTrading is Ownable, ZAP {
    /// @param _opened true means opened and viceversa
    event BlockSalesChanged(
        address indexed _blocker,
        uint256 _blockId,
        uint8 _component,
        uint256 _price,
        IERC20 _Token,
        bool _opened
    );
    event BlockTraded(
        address indexed _buyerBlocker,
        address indexed _sellerBlocker,
        uint256 _blockId,
        uint8 _component,
        uint256 _price,
        IERC20 _Token
    );
    event paymentTokenChanged(IERC20 _token, bool _avaiable);

    IBlock public immutable BLOCK;
    IBlockStorage public immutable BLOCKSTORAGE;
    IBlockAddresses public immutable Addresses;
    mapping(uint256 => mapping(address => BlockSaleInfo)) public blocksForSale; // will be setted by the user
    mapping(IERC20 => bool) public paymnetTokens;

    struct BlockSaleInfo {
        uint8 component;
        bool saleStatus;
        uint256 price;
        IERC20 acceptingToken; // which token you want to receive for your block
    }

    constructor(
        IBlock _tempIBlock,
        IBlockStorage _tempBLOCKSTORAGE,
        IBlockAddresses tempIAddresses
    )
        nonZeroAddress(address(_tempIBlock))
        nonZeroAddress(address(_tempBLOCKSTORAGE))
        nonZeroAddress(address(tempIAddresses))
    {
        BLOCK = _tempIBlock;
        BLOCKSTORAGE = _tempBLOCKSTORAGE;

        Addresses = tempIAddresses;
        // updating the Addresses contract addresses
        Addresses.setBlockTrading(address(this));
    }

    modifier isBlockOwner(uint256 _blockId, uint8 _component) {
        require(
            _component <= BLOCKSTORAGE.getBlockOwner(_blockId, msg.sender),
            "not the Block owner or wrong components requested !!"
        );
        _;
    }

    // before this function this contract must be apporoved for transfering the BLock
    // function is used to start or change a Block sale args
    function openSalesAndPriceTheBlock(
        uint256 _blockId,
        uint8 _component,
        uint256 _price, // must be in decimals
        IERC20 _Token
    ) external isBlockOwner(_blockId, _component) {
        // checking if the Price is at least one unit of the payment token
        require(
            _price >= 10 ** ERC20(address(_Token)).decimals(),
            "price must be more than 1 unit"
        );
        // checking if we are approved
        require(
            BLOCK.isApprovedForAll(msg.sender, address(this)),
            "BlockTrading contract not approved !!"
        );
        BlockSaleInfo memory tempBlockSaleInfo = blocksForSale[_blockId][
            msg.sender
        ];
        // checking if user is not entering the same existing condition
        require(
            tempBlockSaleInfo.component != _component ||
                tempBlockSaleInfo.price != _price ||
                tempBlockSaleInfo.acceptingToken != _Token ||
                !tempBlockSaleInfo.saleStatus,
            "condition already exists"
        );

        if (tempBlockSaleInfo.component != _component)
            tempBlockSaleInfo.component = _component;
        if (tempBlockSaleInfo.price != _price) tempBlockSaleInfo.price = _price;
        if (tempBlockSaleInfo.acceptingToken != _Token)
            tempBlockSaleInfo.acceptingToken = _Token;
        tempBlockSaleInfo.saleStatus = true;
        blocksForSale[_blockId][msg.sender] = tempBlockSaleInfo;
        emit BlockSalesChanged(
            msg.sender,
            _blockId,
            _component,
            _price,
            _Token,
            true
        );
    }

    function closeBlockSales(
        address _blocker,
        uint256 _blockId,
        uint8 _component
    ) public isBlockOwner(_blockId, _component) {
        if (_blocker == msg.sender) {
            // measn an EOA is calling this function.
            _blocker = msg.sender;
        }
        require(
            blocksForSale[_blockId][_blocker].saleStatus,
            "block sales closed already !!"
        );
        blocksForSale[_blockId][_blocker].saleStatus = false;
        emit BlockSalesChanged(
            msg.sender,
            _blockId,
            _component,
            blocksForSale[_blockId][_blocker].price,
            blocksForSale[_blockId][_blocker].acceptingToken,
            false
        );
    }

    // which block , from which blocker, and you wanna buy, the component will be applied directly
    // before this function the Blocker must approve this contract for spending the ERC20 tokens
    function buyBlock(
        uint256 _blockId,
        address _sellerBlocker,
        IERC20 _PaymentToken
    ) external nonZeroAddress(_sellerBlocker) {
        // is the blockSales open for requested blockId
        require(
            blocksForSale[_blockId][_sellerBlocker].saleStatus,
            "block sales are closed for this blockId !!"
        );
        require(
            _PaymentToken.allowance(msg.sender, address(this)) ==
                blocksForSale[_blockId][_sellerBlocker].price,
            "BlockTrading contract not approved !!"
        );
        // checking if the paymnet token is supported and accepted by the `_sellerBlocker` or no.
        require(
            paymnetTokens[_PaymentToken] &&
                blocksForSale[_blockId][_sellerBlocker].acceptingToken ==
                _PaymentToken,
            "payment token not supported !!"
        );
        // closing the BlockSales
        closeBlockSales(
            _sellerBlocker,
            _blockId,
            blocksForSale[_blockId][_sellerBlocker].component
        );

        // calculating the fee amount
        uint256 price_99_percent = feeCalculator.onePercentreducer(
            blocksForSale[_blockId][_sellerBlocker].price
        );
        // transfering the wholePrice amount of paymentToken to this contract from thr `_sellerBlocker`
        require(
            _PaymentToken.transferFrom(
                msg.sender,
                address(this),
                blocksForSale[_blockId][_sellerBlocker].price
            ),
            "failed to transfer whole price from buyerBlocker to this contract"
        );

        // transfering the block to the buyerBlocker
        BLOCK.safeTransferFrom(
            _sellerBlocker,
            msg.sender,
            _blockId,
            blocksForSale[_blockId][_sellerBlocker].component,
            ""
        );
        // updating the storage contract
        BLOCKSTORAGE.transferBlock(
            _sellerBlocker,
            msg.sender,
            _blockId,
            blocksForSale[_blockId][_sellerBlocker].component
        );

        // transfering the 99 percent of price amount of paymentToken for the buyerBlocker from this contract
        require(
            _PaymentToken.transfer(_sellerBlocker, price_99_percent),
            "failed to transfer calculated price from this contract to the sellerBlocker"
        );
        emit BlockTraded(
            msg.sender,
            _sellerBlocker,
            _blockId,
            blocksForSale[_blockId][_sellerBlocker].component,
            blocksForSale[_blockId][_sellerBlocker].price,
            _PaymentToken
        );
    }

    function setPaymentTokens(
        IERC20 _Token
    ) external onlyOwner nonZeroAddress(address(_Token)) {
        require(!paymnetTokens[_Token], "token already supported !!");
        paymnetTokens[_Token] = true;
        emit paymentTokenChanged(_Token, true);
    }

    function unsetPaymentTokens(
        IERC20 _Token
    ) external onlyOwner nonZeroAddress(address(_Token)) {
        require(paymnetTokens[_Token], "token already unsupport ed !!");
        paymnetTokens[_Token] = false;
        emit paymentTokenChanged(_Token, false);
    }

    function getBlocksForSale(
        uint256 _blockId,
        address _blocker
    ) external view returns (BlockSaleInfo memory _BlockSaleInfo) {
        return blocksForSale[_blockId][_blocker];
    }
}
