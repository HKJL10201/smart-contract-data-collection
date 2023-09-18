pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ECDSA.sol";
import "./SignerRole.sol";

contract SmartVoucher is SignerRole {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    uint256 _lastId = block.timestamp;
    uint256 _startId = block.timestamp;
    uint256[] id_array;

    struct Voucher {
        uint256 id;
        address webshop;
        address userwallet;
        uint256 amount;
        uint256 initialAmount;
        uint256 createdAt;
        uint256 validtill;
        address lastRedeemedWebshop;
    }

    struct Userwallet {
        uint256 nonceUserwallet;
    }

    struct Webshop {
        uint256 vouchersCount;
        uint256 lastActivity;
        address[] partners;

        mapping(address => bool) isPartner;
        mapping(uint256 => uint256) vouchersById;
    }

    mapping(uint256 => Voucher) private _vouchers;
    mapping(address => Webshop) private _webshops;
    mapping(address => Userwallet) private _userwallets;

    event VoucherCreated(address indexed webshop, address indexed userwallet, uint256 amount, uint256 indexed id);
    event VoucherRedeemed(address indexed webshop, address indexed userwallet, uint256 amount, uint256 updatedAmount, uint256 indexed id);
    
    event OwnershipTransferred(address indexed rcptwallet, address indexed userwallet, uint256 indexed id);
    event VoucherAmountTransferred(address indexed userwallet, address rcptwallet, uint256 indexed amount1, uint256 amount2, uint256 indexed id1, uint256 id2);

    event PartnersAdded(address indexed webshop, address[] partner);
    event PartnersRemoved(address indexed webshop,address[] partner);

    //---- SETTERS

    function create(
        address webshop,
        address userwallet,
        uint256 amount,
        uint256 validity,
        bytes calldata signature,
        uint256 voucherId
    ) external onlySigner {
        require(webshop != address(0), "invWebshop");
        require(userwallet != address(0), "invUserWallet");
        require(amount > 0, "zeroAmount");
        address signer = getSignerAddress(amount, userwallet, signature);
        require(signer == webshop, "invSigner");

        _userwallets[userwallet].nonceUserwallet++;
        _vouchers[voucherId] = Voucher(voucherId, webshop, userwallet, amount, amount, block.timestamp, validity, address(0));
        _webshops[webshop].vouchersById[_webshops[webshop].vouchersCount + 1] = voucherId;
        _webshops[webshop].vouchersCount++;
        _webshops[webshop].lastActivity = block.timestamp;
        _lastId = voucherId;
        id_array.push(voucherId);

        emit VoucherCreated(webshop, userwallet, amount, voucherId);
    }

    function recreate(
        uint256 id,
        address webshop,
        address userwallet,
        uint256 amount,
        uint256 initialAmount,
        uint256 createdAt,
        uint256 validity,
        address lastRedeemedWebshop
    ) external onlySigner {
        require(webshop != address(0), "invWebshop");

        _vouchers[id] = Voucher(id, webshop, userwallet, amount, initialAmount, createdAt, validity, lastRedeemedWebshop);
        _webshops[webshop].vouchersById[_webshops[webshop].vouchersCount + 1] = id;
        _webshops[webshop].vouchersCount++;
        _webshops[webshop].lastActivity = block.timestamp;
        _lastId = id;
        id_array.push(id);

        emit VoucherCreated(webshop, userwallet, amount, id);
    }

    function transferOwnership(
        address rcptwallet,
        address userwallet,
        uint256 voucherId,
        bytes calldata signature
    ) external onlySigner {
        require(rcptwallet != address(0), "0:invUserWallet");
        require(userwallet != address(0), "1:invUserWallet");
        require(_vouchers[voucherId].userwallet == userwallet, "notBelong");
        require(block.timestamp < _vouchers[voucherId].validtill, "expiredVoucher");
        address signer = getSignerAddress(userwallet, rcptwallet, signature);
        require(signer == userwallet, "invSigner");

        _userwallets[userwallet].nonceUserwallet++;
        _vouchers[voucherId].userwallet = rcptwallet;

        emit OwnershipTransferred(rcptwallet, userwallet, voucherId);
    }

    function transferVoucherAmount(
        address userwallet,
        address rcptwallet,
        uint256 amount,
        uint256 voucherIdfrom,
        uint256 voucherIdto,
        bytes calldata signature
    ) external onlySigner {
        require(userwallet != address(0), "0:invUserWallet");
        require(rcptwallet != address(0), "1:invUserWallet");
        require(amount > 0, "zeroAmount");
        require(block.timestamp < _vouchers[voucherIdfrom].validtill, "0:expiredVoucher");
        require(block.timestamp < _vouchers[voucherIdto].validtill, "1:expiredVoucher");
        require(_vouchers[voucherIdfrom].amount >= amount, "lowAmount");
        require(_vouchers[voucherIdfrom].userwallet == userwallet, "notBelong");
        address signer = getSignerAddress(userwallet, rcptwallet, signature);
        require(signer == userwallet, "invSigner");

        _userwallets[userwallet].nonceUserwallet++;
        _vouchers[voucherIdfrom].amount = _vouchers[voucherIdfrom].amount.sub(amount);
        _vouchers[voucherIdto].amount = _vouchers[voucherIdto].amount.add(amount);

        emit VoucherAmountTransferred(userwallet, rcptwallet, _vouchers[voucherIdfrom].amount, _vouchers[voucherIdto].amount, voucherIdfrom, voucherIdto);
    }

    function redeem(
        address webshop,
        address userwallet,
        uint256 amount,
        uint256 voucherId,
        uint256 nonce,
        bytes calldata signature
    ) external onlySigner {
        require(webshop != address(0), "invWebshop");
        require(userwallet != address(0), "invUserWallet");
        require(amount > 0, "zeroAmount");
        require(webshopAllowedRedeem(webshop, voucherId), "notAllowedWebshop");
        require(_vouchers[voucherId].userwallet == userwallet, "notBelong");
        require(_vouchers[voucherId].amount >= amount, "lowAmount");
        require(block.timestamp < _vouchers[voucherId].validtill, "expiredVoucher");
        require(_userwallets[userwallet].nonceUserwallet == nonce, "invNonce");
        address signer = getSignerAddress(amount, userwallet, signature);
        require(signer == webshop, "invSigner");

        _userwallets[userwallet].nonceUserwallet++;
        _vouchers[voucherId].amount = _vouchers[voucherId].amount.sub(amount);
        _vouchers[voucherId].lastRedeemedWebshop = webshop;
        _webshops[webshop].lastActivity = block.timestamp;

        emit VoucherRedeemed(webshop, userwallet, amount, _vouchers[voucherId].amount, _vouchers[voucherId].id);
    }

    function addPartners(
        address webshop,
        address[] calldata partners,
        bytes calldata signature
    ) external onlySigner {
        require(webshop != address(0), "invWebshop");
        require(partners.length != 0, "invPartners");
        address signer = getSignerAddress(partners[0], signature);
        require(signer == webshop, "invSigner");

        Webshop storage ws = _webshops[webshop];

        for (uint256 index = 0; index < partners.length; index++) {
            if (ws.isPartner[partners[index]] == false) {
                ws.isPartner[partners[index]] = true;
                ws.partners.push(partners[index]);
            }
        }

        ws.lastActivity = block.timestamp;

        emit PartnersAdded(webshop, partners);
    }

    function removePartners(
        address webshop,
        address[] calldata partners,
        bytes calldata signature
    ) external onlySigner {
        require(webshop != address(0), "invWebshop");
        require(partners.length != 0, "invPartners");
        address signer = getSignerAddress(partners[0], signature);
        require(signer == webshop, "invSigner");

        Webshop storage ws = _webshops[webshop];

        for (uint256 index = 0; index < partners.length; index++) {
            if (ws.isPartner[partners[index]] == true) {
                ws.isPartner[partners[index]] = false;

                for (uint256 j = 0; j < ws.partners.length; j++) {
                    if (ws.partners[j] == partners[index]) {
                        ws.partners[j] = ws.partners[ws.partners.length - 1];
                        delete ws.partners[ws.partners.length - 1];
                        ws.partners.length--;
                        break;
                    }
                }
            }
        }

        ws.lastActivity = block.timestamp;

        emit PartnersRemoved(webshop, partners);
    }

    //---- ECDSA GETTERS

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return hash.toEthSignedMessageHash();
    }

    function getSignerAddress(
        uint256 amount,
        address userwallet,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(
                amount,
                userwallet
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        return ECDSA.recover(message, signature);
    }

    function getSignerAddress(
        address userwallet,
        address rcptwallet,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(
                userwallet,
                rcptwallet
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        return ECDSA.recover(message, signature);
    }

    function getSignerAddress(
        address firstPartner,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(
                firstPartner
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        return ECDSA.recover(message, signature);
    }

    //---- GETTERS

    function getLastId() external view returns (uint256) {
        return _lastId;
    }

    function getStartId() external view returns (uint256) {
        return _startId;
    }

    function getVoucherData(uint256 voucherId) external view returns (
        uint256 id,
        address webshop,
        address userwallet,
        uint256 amount,
        uint256 initialAmount,
        uint256 createdAt,
        uint256 validtill,
        address lastRedeemedWebshop
    ) {
        Voucher memory voucher = _vouchers[voucherId];
        return (
            voucher.id,
            voucher.webshop,
            voucher.userwallet,
            voucher.amount,
            voucher.initialAmount,
            voucher.createdAt,
            voucher.validtill,
            voucher.lastRedeemedWebshop
        );
    }

    function getAllVoucherIds() external view returns (
        uint256[] memory array
    ){
        return id_array;
    }

    function getUserwalletData(address userwalletAddr) external view returns (
        uint256 nonceUserwallet
    ){
        Userwallet memory userwallet = _userwallets[userwalletAddr];
        return (
            userwallet.nonceUserwallet
        );
    }

    function getWebshopData(address webshopAddr) external view returns (
        uint256 lastActivity,
        address[] memory partners,
        uint256 vouchersCount
    ) {
        Webshop memory webshop = _webshops[webshopAddr];
        return (
            webshop.lastActivity,
            webshop.partners,
            webshop.vouchersCount
        );
    }

    function isWebshopExist(address webshopAddr) external view returns (bool isExist) {
        isExist = _webshops[webshopAddr].lastActivity > 0;
        return isExist;
    }

    function webshopAllowedRedeem(address webshop, uint256 voucherId) public view returns (bool) {
        bool isOwnerPartner = isWebshopPartner(_vouchers[voucherId].webshop, webshop);
        bool voucherOwner = isVoucherOwnedByWebshop(webshop, voucherId);
        return voucherOwner || isOwnerPartner;
    }

    function isWebshopPartner(address webshop, address partner) public view returns (bool isPartner) {
        isPartner = _webshops[webshop].isPartner[partner];
        return isPartner;
    }

    function isVoucherOwnedByWebshop(address webshopAddr, uint256 voucherId) public view returns (bool isOwned) {
        isOwned = _vouchers[voucherId].webshop == webshopAddr;
        return isOwned;
    }
}