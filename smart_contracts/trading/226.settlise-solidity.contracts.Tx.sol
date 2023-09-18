// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./TxFactory.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Tx {
    using SafeMath for uint;

    address public TxFactoryContractAddress;

    string public ipfsImage;
    string item;
    uint256 price;
    string sellerPhysicalAddress;
    uint256 id;

    string buyerPhysicalAddress;

    uint256 multipleOfPrice = 2;

    uint256 sellerCollateral;
    uint256 buyerCollateral;
    uint256 costCollateral;

    uint256 tipForSeller;
    uint256 tipForBuyer;

    bool dispute;
    address buyer;
    address seller;
    bool sellerSettled;
    bool buyerSettled;
    bool pending;
    bool finalSettlement;

    error Transfer__Failed();

    constructor(
        string memory _ipfsImage,
        string memory _item,
        uint256 _price,
        string memory _sellerPhysicalAddress,
        address _sellerAddress,
        uint256 _id,
        address _TxFactoryContractAddress
    ) payable {
        require(msg.value >= _price, "You did not put enough collateral funds");

        item = _item;
        price = _price;
        sellerPhysicalAddress = _sellerPhysicalAddress;
        id = _id;

        seller = _sellerAddress;

        ipfsImage = _ipfsImage;

        TxFactoryContractAddress = _TxFactoryContractAddress;

        sellerCollateral += _price;

        TxFactory(TxFactoryContractAddress).setTransaction(
            seller,
            address(this)
        );
    }

    function purchase(string memory _buyerPhysicalAddress) public payable {
        require(
            msg.value == price * multipleOfPrice,
            "Not enough memony to purchase"
        );
        buyer=msg.sender;
        TxFactory(TxFactoryContractAddress).setBuyerTransaction(
            msg.sender,
            address(this)
        );
        TxFactory(TxFactoryContractAddress).removeFromPublicArray(
            address(this)
        );
        buyerPhysicalAddress = _buyerPhysicalAddress;
        buyer = msg.sender;
        pending = true;
        buyerCollateral = price;
        costCollateral = price;
    }

    function setDispute() public {
        require(msg.sender == buyer, "You are not authorized to dispute");
        dispute = true;
    }

    function tipSeller() public payable {
        require(msg.sender == buyer, "You are not authorized to to tip");
        tipForSeller += msg.value;
    }

    function tipBuyer() public payable {
        require(msg.sender == seller, "You are not authorized to tip");
        tipForBuyer += msg.value;
    }

    function payOutBuyer(address _msgSender) public {
        require(_msgSender == buyer, "You are not authorized to settle");
        if (dispute == false) {
            (bool success0, ) = seller.call{
                value: sellerCollateral.add(tipForSeller).add(costCollateral)
            }("");
            (bool success1, ) = buyer.call{
                value: buyerCollateral.add(tipForBuyer)
            }("");
            if (!success0) {
                revert Transfer__Failed();
            }
            if (!success1) {
                revert Transfer__Failed();
            }
            buyerCollateral = 0;
            sellerCollateral = 0;
            tipForBuyer = 0;
            tipForSeller = 0;
            finalSettlement = true;
            pending = false;
        } else {
            if (sellerSettled == true) {
                TxFactory(TxFactoryContractAddress).removeTx(
                    address(this),
                    seller,
                    buyer
                );
                (bool success0, ) = seller.call{
                    value: sellerCollateral.add(tipForSeller).add(
                        costCollateral
                    )
                }("");
                (bool success1, ) = buyer.call{
                    value: buyerCollateral.add(tipForBuyer)
                }("");
                if (!success0) {
                    revert();
                }
                if (!success1) {
                    revert();
                }
                finalSettlement = true;
                pending = false;
                tipForBuyer = 0;
                tipForSeller = 0;
                buyerCollateral = 0;
                sellerCollateral = 0;
            }
        }
    }

    function buyerSettle() public {
        require(msg.sender == buyer, "You are not authorized to settle");
        buyerSettled = true;
        payOutBuyer(msg.sender);
    }

    function payOutSeller(address _msgSender) public {
        require(_msgSender == seller, "You are not authorized to settle");
        if (dispute == true && buyerSettled == true) {
            (bool success0, ) = seller.call{
                value: sellerCollateral.add(tipForSeller).add(costCollateral)
            }("");
            (bool success1, ) = buyer.call{
                value: buyerCollateral.add(tipForBuyer)
            }("");
            if (!success0) {
                revert();
            }
            if (!success1) {
                revert();
            }
            finalSettlement = true;
            pending = false;
            tipForBuyer = 0;
            tipForSeller = 0;
            buyerCollateral = 0;
            sellerCollateral = 0;
        }
    }

    function sellerSettle() public {
        require(msg.sender == seller, "You are not authorized to settle");
        sellerSettled = true;
        payOutSeller(msg.sender);
    }

    function sellerRefund() public {
        require(msg.sender == seller, "You are not autherized to refund");
        (bool success0, ) = seller.call{
            value: sellerCollateral.add(tipForSeller)
        }("");
        (bool success1, ) = buyer.call{value: buyerCollateral.add(tipForBuyer).add(costCollateral)}(
            ""
        );
        if (!success0) {
            revert();
        }
        if (!success1) {
            revert();
        }
        finalSettlement = true;
        pending = false;
        tipForBuyer = 0;
        tipForSeller = 0;
        buyerCollateral = 0;
        sellerCollateral = 0;
    }

    //Getter functions

    function getSellerAddress() public view returns (address) {
        return seller;
    }

    function getBuyerAddress() public view returns (address) {
        return buyer;
    }

    function getTransactionAddress() public view returns (address) {
        return address(this);
    }

    function getSellerCollateral() public view returns (uint256) {
        return sellerCollateral;
    }

    function getBuyerCollateral() public view returns (uint256) {
        return buyerCollateral;
    }

    function getItem() public view returns (string memory) {
        return item;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function getSellerPhysicalAddress() public view returns (string memory) {
        return sellerPhysicalAddress;
    }

    function getBuyerPhysicalAddress() public view returns (string memory) {
        return buyerPhysicalAddress;
    }

    function getId() public view returns (uint256) {
        return id;
    }

    function getTotalContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPending() public view returns (bool) {
        return pending;
    }

    function getFinalSettlement() public view returns (bool) {
        return finalSettlement;
    }

    function getDispute() public view returns (bool) {
        return dispute;
    }

    function getTipForBuyer() public view returns (uint256) {
        return tipForBuyer;
    }

    function getTipForSeller() public view returns (uint256) {
        return tipForSeller;
    }

    function getSellerSettled() public view returns (bool) {
        return sellerSettled;
    }

    function getBuyerSettled() public view returns (bool) {
        return buyerSettled;
    }

    function getCost() public view returns (uint256) {
        return costCollateral;
    }

    function getIpfsImage() public view returns (string memory) {
        return ipfsImage;
    }
}