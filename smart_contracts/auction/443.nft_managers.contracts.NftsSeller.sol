// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                            IMPORTS                          //
//=============================================================//
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./NftsManagerBase.sol";


/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  NFTs seller
 * @notice It allows users to buy a ERC721 or ERC1155 NFT for a specific ERC20 token amount (e.g. stable coins).
 *         The NFTs to be sold are set by the contract owner.
 */
contract NftsSeller is
    ReentrancyGuard,
    NftsManagerBase
{
    //=============================================================//
    //                         STRUCTURES                          //
    //=============================================================//

    /// Structure for sale data
    struct Sale {
        uint256 nftAmount;      // Only used for ERC1155 (always 0 for ERC721)
        IERC20 erc20Contract;
        uint256 erc20Amount;
        bool isActive;
    }

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if a token sale is already created for the `nftContract` and `nftId`
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    error SaleAlreadyCreatedError(
        address nftContract,
        uint256 nftId
    );

    /**
     * Error raised if a token sale is not created for the `nftContract` and `nftId`
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    error SaleNotCreatedError(
        address nftContract,
        uint256 nftId
    );

    //=============================================================//
    //                             EVENTS                          //
    //=============================================================//

    /**
     * Event emitted when a sale is created
     * @param nftContract   NFT contract address
     * @param nftId         NFT ID
     * @param nftAmount     NFT amount
     * @param erc20Contract ERC20 contract address
     * @param erc20Amount   ERC20 amount to pay for the sale
     */
    event SaleCreated(
        address nftContract,
        uint256 nftId,
        uint256 nftAmount,
        IERC20 erc20Contract,
        uint256 erc20Amount
    );

    /**
     * Event emitted when a sale is removed
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    event SaleRemoved(
        address nftContract,
        uint256 nftId
    );

    /**
     * Event emitted when a sale is completed
     * @param buyer         Buyer address
     * @param nftContract   NFT contract address
     * @param nftId         NFT ID
     * @param nftAmount     NFT amount
     * @param erc20Contract ERC20 contract address
     * @param erc20Amount   ERC20 amount to pay for the sale
     */
    event SaleCompleted(
        address buyer,
        address nftContract,
        uint256 nftId,
        uint256 nftAmount,
        IERC20 erc20Contract,
        uint256 erc20Amount
    );

    //=============================================================//
    //                            STORAGE                          //
    //=============================================================//

    /// Mapping from token address and ID to sale data
    mapping(address => mapping(uint256 => Sale)) public Sales;

    //=============================================================//
    //                       PUBLIC FUNCTIONS                      //
    //=============================================================//

    /**
     * Get if a sale is active
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @return True if active, false otherwise
     */
    function isSaleActive(
        address nftContract_,
        uint256 nftId_
    ) external view returns (bool) {
        Sale storage sale = Sales[nftContract_][nftId_];
        return sale.isActive;
    }

    /**
     * Create a ERC721 token sale
     * The token shall be owned by the contract
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   Price of the ERC721 token in ERC20 token
     */
    function createERC721Sale(
        IERC721 nftContract_,
        uint256 nftId_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    ) public onlyOwner {
        __createSale(
            address(nftContract_),
            nftId_,
            0,
            erc20Contract_,
            erc20Amount_
        );
    }

    /**
     * Create a ERC1155 token sale
     * The token shall be owned by the contract
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param nftAmount_     NFT amount
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount
     */
    function createERC1155Sale(
        IERC1155 nftContract_,
        uint256 nftId_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    )
        public
        onlyOwner
        notZeroAmount(nftAmount_)
    {
        __createSale(
            address(nftContract_),
            nftId_,
            nftAmount_,
            erc20Contract_,
            erc20Amount_
        );
    }

    /**
     * Remove a token sale
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function removeSale(
        address nftContract_,
        uint256 nftId_
    ) public onlyOwner {
        __removeSale(nftContract_, nftId_);
    }

    /**
     * Withdraw a ERC721 token to owner.
     * The token shall not be on sale. In case it is, it shall be removed before calling the function.
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function withdrawERC721(
        IERC721 nftContract_,
        uint256 nftId_
    ) public onlyOwner {
        __withdraw(
            address(nftContract_),
            nftId_,
            0
        );
    }

    /**
     * Withdraw a ERC1155 token to owner.
     * The token shall not be on sale. In case it is, it shall be removed before calling the function.
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount (ignored for ERC721)
     */
    function withdrawERC1155(
        IERC1155 nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    )
        public
        onlyOwner
        notZeroAmount(nftAmount_)
    {
        __withdraw(
            address(nftContract_),
            nftId_,
            nftAmount_
        );
    }

    /**
     * Buy a ERC721 token
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function buyERC721(
        IERC721 nftContract_,
        uint256 nftId_
    ) public nonReentrant {
        __buy(
            address(nftContract_),
            nftId_,
            0
        );
    }

    /**
     * Buy a ERC1155 token
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount (ignored for ERC721)
     */
    function buyERC1155(
        IERC1155 nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    )
        public
        nonReentrant
        notZeroAmount(nftAmount_)
    {
        __buy(
            address(nftContract_),
            nftId_,
            nftAmount_
        );
    }

    //=============================================================//
    //                      INTERNAL FUNCTIONS                     //
    //=============================================================//

    /**
     * Initialize the sale `sale_`
     * @param sale_          Sale structure
     * @param nftAmount_     NFT amount
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount
     */
    function __initSale(
        Sale storage sale_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    ) private {
        sale_.nftAmount = nftAmount_;
        sale_.erc20Contract = erc20Contract_;
        sale_.erc20Amount = erc20Amount_;
        sale_.isActive = true;
    }

    /**
     * Create a token sale
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param nftAmount_     NFT amount
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount
     */
    function __createSale(
        address nftContract_,
        uint256 nftId_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    )
        private 
        notNullAddress(address(erc20Contract_))
    {
        if (nftAmount_ == 0) {
            _validateERC721(IERC721(nftContract_), nftId_);
        }
        else {
            _validateERC1155(IERC1155(nftContract_), nftId_, nftAmount_);
        }
    
        Sale storage sale = Sales[nftContract_][nftId_];
        if (sale.isActive) {
            revert SaleAlreadyCreatedError(nftContract_, nftId_);
        }

        __initSale(
            sale,
            nftAmount_,
            erc20Contract_,
            erc20Amount_
        );

        emit SaleCreated(
            nftContract_,
            nftId_,
            nftAmount_,
            erc20Contract_,
            erc20Amount_
        );
    }

    /**
     * Remove a token sale
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function __removeSale(
        address nftContract_,
        uint256 nftId_
    )
        private
        notNullAddress(address(nftContract_))
    {
        Sale storage sale = Sales[nftContract_][nftId_];
        if (!sale.isActive) {
            revert SaleNotCreatedError(nftContract_, nftId_);
        }

        sale.isActive = false;

        emit SaleRemoved(nftContract_, nftId_);
    }

    /**
     * Withdraw token to owner
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount (ignored for ERC721)
     */
    function __withdraw(
        address nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    )
        private
        notNullAddress(nftContract_)
    {
        address target = owner();

        Sale storage sale = Sales[nftContract_][nftId_];
        if (sale.isActive) {
            if (nftAmount_ == 0) {
                revert WithdrawError(nftContract_, nftId_);
            }
            uint256 withdrawable_amount = IERC1155(nftContract_).balanceOf(address(this), nftId_) - sale.nftAmount;
            if (nftAmount_ > withdrawable_amount) {
                revert WithdrawError(nftContract_, nftId_);
            }
        }

        if (nftAmount_ == 0) {
            _withdrawERC721(
                target, 
                IERC721(nftContract_),
                nftId_
            );
        } 
        else {
            _withdrawERC1155(
                target, 
                IERC1155(nftContract_),
                nftId_,
                nftAmount_
            );
        }
    }

    /**
     * Buy a token
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount (ignored for ERC721)
     */
    function __buy(
        address nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    )
        private
        notNullAddress(nftContract_)
    {
        Sale storage sale = Sales[nftContract_][nftId_];
        if (!sale.isActive) {
            revert SaleNotCreatedError(nftContract_, nftId_);
        }

        if (sale.nftAmount == 0) {
            __buyERC721(
                sale,
                nftContract_,
                nftId_
            );
        }
        else {
            __buyERC1155(
                sale,
                nftContract_,
                nftId_,
                nftAmount_
            );
        }

        emit SaleCompleted(
            _msgSender(),
            nftContract_,
            nftId_,
            nftAmount_,
            sale.erc20Contract,
            sale.erc20Amount
        );
    }

    /**
     * Buy a ERC721 token
     * @param sale_        Sale structure
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function __buyERC721(
        Sale storage sale_,
        address nftContract_,
        uint256 nftId_
    ) private {
        sale_.isActive = false;

        _transferERC721InExchangeOfERC20(
            _msgSender(),
            IERC721(nftContract_),
            nftId_,
            sale_.erc20Contract,
            sale_.erc20Amount
        );
    }

    /**
     * Buy a ERC1155 token
     * @param sale_        Sale structure
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function __buyERC1155(
        Sale storage sale_,
        address nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    ) private {
        if (nftAmount_ > sale_.nftAmount) {
            revert AmountError();
        }

        // Reset if no more token left
        sale_.nftAmount -= nftAmount_;
        if (sale_.nftAmount == 0) {
            sale_.isActive = false;
        }

        _transferERC1155InExchangeOfERC20(
            _msgSender(),
            IERC1155(nftContract_),
            nftId_,
            nftAmount_,
            sale_.erc20Contract,
            sale_.erc20Amount * nftAmount_
        );
    }
}
