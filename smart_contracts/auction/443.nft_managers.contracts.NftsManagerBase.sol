// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                            IMPORTS                          //
//=============================================================//
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IERC20Receiver.sol";


/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Base constract for NFT managers
 */
abstract contract NftsManagerBase is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IERC721Receiver,
    IERC1155Receiver
{
    using Address for address;
    using SafeERC20 for IERC20;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised in case of an amount error
     */ 
    error AmountError();

    /**
     * Error raised in case of a NFT error
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */ 
    error NftError(
        address nftContract,
        uint256 nftId
    );

    /**
     * Error raised in case of a null address
     */
    error NullAddressError();

    /**
     * Error raised in case of a withdraw error
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */ 
    error WithdrawError(
        address nftContract,
        uint256 nftId
    );

    /**
     * Error raised in case the onERC20Received function returns the wrong value
     */ 
    error IERC20ReceiverRetValError();

    /**
     * Error raised in case the onERC20Received function is not implemented
     */ 
    error IERC20ReceiverNotImplError();

    //=============================================================//
    //                             EVENTS                          //
    //=============================================================//

    /**
     * Event emitted when the payment ERC20 address is changed
     * @param oldAddress Old address
     * @param newAddress New address
     */
    event PaymentERC20AddressChanged(
        address oldAddress,
        address newAddress
    );

    /**
     * Event emitted when a ERC721 token is withdrawn
     * @param target      Target address
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    event ERC721Withdrawn(
        address target,
        IERC721 nftContract,
        uint256 nftId
    );

    /**
     * Event emitted when a ERC1155 token is withdrawn
     * @param target      Target address
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     * @param nftAmount   NFT amount
     */
    event ERC1155Withdrawn(
        address target,
        IERC1155 nftContract,
        uint256 nftId,
        uint256 nftAmount
    );

    //=============================================================//
    //                           MODIFIERS                         //
    //=============================================================//

    /**
     * Modifier to make a function callable only if the address `address_` is not null
     * @param address_ Address
     */
    modifier notNullAddress(
        address address_
    ) {
        if (address_ == address(0)) {
            revert NullAddressError();
        }
        _;
    }

    /**
     * Modifier to make a function callable only if the amount `amount_` is not zero
     * @param amount_ Amount
     */
    modifier notZeroAmount(
        uint256 amount_
    ) {
        if (amount_ == 0) {
            revert AmountError();
        }
        _;
    }

    //=============================================================//
    //                            STORAGE                          //
    //=============================================================//

    /// Wallet address where ERC20 tokens will be transferred
    address public paymentERC20Address;

    //=============================================================//
    //                          CONSTRUCTOR                        //
    //=============================================================//

    /**
     * Constructor
     * @dev Disable initializer for implementation contract
     */
    constructor() {
        _disableInitializers();
    }

    //=============================================================//
    //                       PUBLIC FUNCTIONS                      //
    //=============================================================//

    /**
     * Initialize
     * @param paymentERC20Address_ ERC20 payment address
     */
    function init(
        address paymentERC20Address_
    ) public initializer {
        __Ownable_init();
        __setPaymentERC20Address(paymentERC20Address_);
    }

    /**
     * Set payment ERC20 address
     * @param paymentERC20Address_ ERC20 payment address
     */
    function setPaymentERC20Address(
        address paymentERC20Address_
    ) public onlyOwner {
        __setPaymentERC20Address(paymentERC20Address_);
    }

    //=============================================================//
    //                      INTERNAL FUNCTIONS                     //
    //=============================================================//

    /**
     * Revert if the ERC721 token is not valid
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function _validateERC721(
        IERC721 nftContract_,
        uint256 nftId_
    )
        internal
        view
        notNullAddress(address(nftContract_))
    {
        // NFT shall be minted
        try nftContract_.ownerOf(nftId_) returns (address) {
        } catch {
            revert NftError(
                address(nftContract_),
                nftId_
            );
        }

        // NFT shall be owned by the contract
        if (nftContract_.ownerOf(nftId_) != address(this)) {
            revert NftError(
                address(nftContract_),
                nftId_
            );  
        }
    }

    /**
     * Revert if the ERC1155 token is not valid
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount
     */
    function _validateERC1155(
        IERC1155 nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    )
        internal
        view
        notNullAddress(address(nftContract_))
    {
        if (nftContract_.balanceOf(address(this), nftId_) < nftAmount_) {
            revert NftError(
                address(nftContract_),
                nftId_
            );
        }
    }

    /**
     * Withdraw ERC721 token to `target_`
     * @param target_      Target address
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function _withdrawERC721(
        address target_,
        IERC721 nftContract_,
        uint256 nftId_
    )
        internal
        notNullAddress(address(nftContract_))
    {
        nftContract_.safeTransferFrom(
            nftContract_.ownerOf(nftId_), 
            target_, 
            nftId_
        );

        emit ERC721Withdrawn(
            target_,
            nftContract_,
            nftId_
        );
    }

    /**
     * Withdraw ERC1155 token to `target_`
     * @param target_      Target address
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount
     */
    function _withdrawERC1155(
        address target_,
        IERC1155 nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    )
        internal
        notNullAddress(address(nftContract_))
        notZeroAmount(nftAmount_)
    {
        nftContract_.safeTransferFrom(
            address(this),
            target_, 
            nftId_,
            nftAmount_,
            ""
        );

        emit ERC1155Withdrawn(
            target_,
            nftContract_,
            nftId_,
            nftAmount_
        );
    }

    /**
     * Transfer a ERC721 token in exchange of ERC20 token
     * @param user_          User address
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount to pay for the redeem
     * @dev The ERC20 token shall be approved by the target address
     *      The ERC721 token shall be owned by the contract
     */
    function _transferERC721InExchangeOfERC20(
        address user_,
        IERC721 nftContract_,
        uint256 nftId_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    ) internal {
        __transferERC20(
            user_,
            erc20Contract_,
            erc20Amount_
        );
        nftContract_.safeTransferFrom(
            address(this), 
            user_, 
            nftId_
        );
    }

    /**
     * Transfer a ERC1155 token in exchange of ERC20 token
     * @param user_          User address
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param nftAmount_     NFT amount
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount to pay for the redeem
     * @dev The ERC20 token shall be approved by the target address
     *      The ERC1155 token shall be owned by the contract
     */
    function _transferERC1155InExchangeOfERC20(
        address user_,
        IERC1155 nftContract_,
        uint256 nftId_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    ) internal {
        __transferERC20(
            user_,
            erc20Contract_,
            erc20Amount_
        );
        nftContract_.safeTransferFrom(
            address(this),
            user_, 
            nftId_,
            nftAmount_,
            ""
        );
    }

    //=============================================================//
    //                       PRIVATE FUNCTIONS                     //
    //=============================================================//

    /**
     * Set payment ERC20 address
     * @param paymentERC20Address_ ERC20 payment address
     */
    function __setPaymentERC20Address(
        address paymentERC20Address_
    ) private notNullAddress(paymentERC20Address_) {
        address old_address = paymentERC20Address;
        paymentERC20Address = paymentERC20Address_;

        emit PaymentERC20AddressChanged(old_address, paymentERC20Address);
    }


    /**
     * Transfer ERC20 token
     * @param user_          User address
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount to pay for the redeem
     */
    function __transferERC20(
        address user_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    ) private {
        erc20Contract_.safeTransferFrom(
            user_,
            paymentERC20Address,
            erc20Amount_
        );

        if (paymentERC20Address.isContract()) {
            try IERC20Receiver(paymentERC20Address).onERC20Received(erc20Contract_, erc20Amount_) returns (bytes4 ret) {
                if (ret != IERC20Receiver.onERC20Received.selector) {
                    revert IERC20ReceiverRetValError();
                }
            } catch {
                revert IERC20ReceiverNotImplError();
            }
        }
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * Restrict upgrade to owner
     * See {UUPSUpgradeable-_authorizeUpgrade}
     */
    function _authorizeUpgrade(
        address newImplementation_
    ) internal override onlyOwner
    {}

    /**
     * See {IERC721Receiver-onERC721Received}
     */
    function onERC721Received(
        address operator_,
        address from_,
        uint256 tokenId_,
        bytes calldata data_
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * See {IERC1155Receiver-onERC1155Received}
     */
    function onERC1155Received(
        address operator_,
        address from_,
        uint256 id_,
        uint256 value_,
        bytes calldata data_
    ) external override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * See {IERC1155Receiver-onERC1155BatchReceived}
     */
    function onERC1155BatchReceived(
        address operator_,
        address from_,
        uint256[] calldata ids_,
        uint256[] calldata values_,
        bytes calldata data_
    ) external override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /**
     * See {IERC165-supportsInterface}
     */
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override returns (bool) {
        return false;
    }
}
