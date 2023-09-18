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
 * @title  NFTs redeemer
 * @notice It allows to reserve a ERC721 or ERC1155 token for a specific wallet, which can redeem it by paying in ERC20 tokens (e.g. stablecoins).
 *         The NFTs to be redeemed are set by the contract owner.
 */
contract NftsRedeemer is 
    ReentrancyGuard,
    NftsManagerBase
{
    //=============================================================//
    //                         STRUCTURES                          //
    //=============================================================//

    /// Structure for redeem data
    struct Redeem {
        address nftContract;
        uint256 nftId;
        uint256 nftAmount;      // Only used for ERC1155 (always 0 for ERC721)
        IERC20 erc20Contract;
        uint256 erc20Amount;
        bool isActive;
    }

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if a token redeem is already created for the `reedemer`
     * @param reedemer Redeemer address
     */
    error RedeemAlreadyCreatedError(
        address reedemer
    );

    /**
     * Error raised if a token redeem is not created for the `reedemer`
     * @param reedemer Redeemer address
     */
    error RedeemNotCreatedError(
        address reedemer
    );

    //=============================================================//
    //                             EVENTS                          //
    //=============================================================//

    /**
     * Event emitted when a redeem is created
     * @param redeemer      Redeemer address
     * @param nftContract   NFT contract address
     * @param nftId         NFT ID
     * @param nftAmount     NFT amount
     * @param erc20Contract ERC20 contract address
     * @param erc20Amount   ERC20 amount to pay for the redeem
     */
    event RedeemCreated(
        address redeemer,
        address nftContract,
        uint256 nftId,
        uint256 nftAmount,
        IERC20 erc20Contract,
        uint256 erc20Amount
    );

    /**
     * Event emitted when a redeem is removed
     * @param redeemer    Redeemer address
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    event RedeemRemoved(
        address redeemer,
        address nftContract,
        uint256 nftId
    );

    /**
     * Event emitted when a redeem is completed
     * @param redeemer      Redeemer address
     * @param nftContract   NFT contract address
     * @param nftId         NFT ID
     * @param nftAmount     NFT amount
     * @param erc20Contract ERC20 contract address
     * @param erc20Amount   ERC20 amount to pay for the redeem
     */
    event RedeemCompleted(
        address redeemer,
        address nftContract,
        uint256 nftId,
        uint256 nftAmount,
        IERC20 erc20Contract,
        uint256 erc20Amount
    );

    //=============================================================//
    //                            STORAGE                          //
    //=============================================================//

    /// Mapping from wallet address to redeem data
    mapping(address => Redeem) public Redeems;
    /// Mapping from token address and ID to redeemer address
    mapping(address => mapping(uint256 => address)) public Redeemers;

    //=============================================================//
    //                       PUBLIC FUNCTIONS                      //
    //=============================================================//

    /**
     * Get if a redeem is active
     * @param redeemer_ Redeemer address
     * @return True if active, false otherwise
     */
    function isRedeemActive(
        address redeemer_
    ) external view returns (bool) {
        Redeem storage redeem = Redeems[redeemer_];
        return redeem.isActive;
    }

    /**
     * Get if a redeem is active
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @return True if active, false otherwise
     */
    function isRedeemActive(
        address nftContract_,
        uint256 nftId_
    ) external view returns (bool) {
        Redeem storage redeem = Redeems[Redeemers[nftContract_][nftId_]];
        return redeem.isActive;
    }

    /**
     * Create a ERC721 token redeem
     * The NFT shall be owned by the contract
     * @param redeemer_      Redeemer address
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount to pay for the redeem
     */
    function createERC721Redeem(
        address redeemer_,
        IERC721 nftContract_,
        uint256 nftId_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    ) public onlyOwner {
        __createRedeem(
            redeemer_,
            address(nftContract_),
            nftId_,
            0,
            erc20Contract_,
            erc20Amount_
        );
    }

    /**
     * Create a ERC1155 token redeem
     * The NFT shall be owned by the contract
     * @param redeemer_      Redeemer address
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param nftAmount_     NFT amount
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount to pay for the redeem
     */
    function createERC1155Redeem(
        address redeemer_,
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
        __createRedeem(
            redeemer_,
            address(nftContract_),
            nftId_,
            nftAmount_,
            erc20Contract_,
            erc20Amount_
        );
    }

    /**
     * Remove a token redeem
     * @param redeemer_ Redeemer address
     */
    function removeRedeem(
        address redeemer_
    ) public onlyOwner {
        __removeRedeem(redeemer_);
    }

    /**
     * Withdraw ERC721 token to owner.
     * The token shall not be on redeem. In case it is, it shall be removed before calling the function.
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
     * Withdraw ERC1155 token to owner.
     * The token shall not be on redeem. In case it is, it shall be removed before calling the function.
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount
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
     * Redeem a token
     */
    function redeemToken() public nonReentrant {
        __redeemToken();
    }

    //=============================================================//
    //                      INTERNAL FUNCTIONS                     //
    //=============================================================//
    
    /**
     * Initialize the redeem `redeem_`
     * @param redeem_        Redeem structure
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param nftAmount_     NFT amount
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount
     */
    function __initRedeem(
        Redeem storage redeem_,
        address nftContract_,
        uint256 nftId_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    ) private {
        redeem_.nftContract = nftContract_;
        redeem_.nftId = nftId_;
        redeem_.nftAmount = nftAmount_;
        redeem_.erc20Contract = erc20Contract_;
        redeem_.erc20Amount = erc20Amount_;
        redeem_.isActive = true;
    }

    /**
     * Create a token redeem
     * @param redeemer_      Redeemer address
     * @param nftContract_   NFT contract address
     * @param nftId_         NFT ID
     * @param nftAmount_     NFT amount
     * @param erc20Contract_ ERC20 contract address
     * @param erc20Amount_   ERC20 amount to pay for the redeem
     */
    function __createRedeem(
        address redeemer_,
        address nftContract_,
        uint256 nftId_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20Amount_
    ) 
        private 
        notNullAddress(redeemer_)
        notNullAddress(address(erc20Contract_)) 
    {
        if (nftAmount_ == 0) {
            _validateERC721(IERC721(nftContract_), nftId_);
        }
        else {
            _validateERC1155(IERC1155(nftContract_), nftId_, nftAmount_);
        }

        address current_redeemer = Redeemers[nftContract_][nftId_];
        if (current_redeemer != address(0)) {
            revert RedeemAlreadyCreatedError(current_redeemer);
        }

        Redeem storage redeem = Redeems[redeemer_];
        if (redeem.isActive) {
            revert RedeemAlreadyCreatedError(redeemer_);
        }

        Redeemers[nftContract_][nftId_] = redeemer_;

        __initRedeem(
            Redeems[redeemer_],
            nftContract_,
            nftId_,
            nftAmount_,
            erc20Contract_,
            erc20Amount_
        );

        emit RedeemCreated(
            redeemer_,
            nftContract_,
            nftId_,
            nftAmount_,
            erc20Contract_,
            erc20Amount_
        );
    }

    /**
     * Remove a token redeem
     * @param redeemer_ Redeemer address
     */
    function __removeRedeem(
        address redeemer_
    )
        private
        notNullAddress(redeemer_)
    {
        Redeem storage redeem = Redeems[redeemer_];
        if (Redeemers[redeem.nftContract][redeem.nftId] == address(0)) {
            revert RedeemNotCreatedError(redeemer_);
        }

        Redeemers[redeem.nftContract][redeem.nftId] = address(0);
        redeem.isActive = false;

        emit RedeemRemoved(
            redeemer_,
            redeem.nftContract,
            redeem.nftId
        );
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

        address redeemer = Redeemers[nftContract_][nftId_];
        if (redeemer != address(0)) {
            Redeem storage redeem = Redeems[redeemer];

            if (nftAmount_ == 0) {
                revert WithdrawError(nftContract_, nftId_);
            }
            uint256 withdrawable_amount = IERC1155(nftContract_).balanceOf(address(this), nftId_) - redeem.nftAmount;
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
     * Redeem a token
     */
    function __redeemToken() private {
        address redeemer = _msgSender();

        Redeem storage redeem = Redeems[redeemer];
        if (Redeemers[redeem.nftContract][redeem.nftId] == address(0)) {
            revert RedeemNotCreatedError(redeemer);
        }

        Redeemers[redeem.nftContract][redeem.nftId] = address(0);
        redeem.isActive = false;

        if (redeem.nftAmount == 0) {
            _transferERC721InExchangeOfERC20(
                redeemer,
                IERC721(redeem.nftContract),
                redeem.nftId,
                redeem.erc20Contract,
                redeem.erc20Amount
            );
        }
        else {
            _transferERC1155InExchangeOfERC20(
                redeemer,
                IERC1155(redeem.nftContract),
                redeem.nftId,
                redeem.nftAmount,
                redeem.erc20Contract,
                redeem.erc20Amount
            );
        }

        emit RedeemCompleted(
            redeemer,
            redeem.nftContract,
            redeem.nftId,
            redeem.nftAmount,
            redeem.erc20Contract,
            redeem.erc20Amount
        );
    }
}
