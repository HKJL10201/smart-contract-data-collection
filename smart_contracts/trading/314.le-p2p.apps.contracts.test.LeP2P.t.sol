// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";
import "@iden3/contracts/interfaces/ICircuitValidator.sol";
import "./mocks/MockWorldId.sol";
import "./mocks/USDCMock.sol";
import "./mocks/CircuitMock.sol";
import "../src/LeP2P.sol";

contract LeP2PTest is Test {
    using stdStorage for StdStorage;
    LeP2PEscrow public escrow;
    USDCMock public token;
    MockWorldId public worldId;
    address public constant BUYER = address(1);
    address public constant SELLER = address(2);
    address public constant ARBITRATOR = address(3);
    address public constant SELLER_2 = address(4);
    address public constant BUYER_2 = address(5);
    address public constant NOT_REGISTERED_SELLER = address(101);
    address public constant NOT_REGISTERED_BUYER = address(102);
    uint256 public constant INITIAL_CAPITAL = 1e6 * 2000;
    uint256 public allowedAmount;
    string public constant IBAN = "ES6621000418401234567891";
    uint256 public constant FIAT_TO_TOKEN_EXCHANGE_RATE = 10;
    string public constant IPFS_HASH = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
    string public constant REASON = "test";

    event OrderCreated(uint256 id, address seller, uint256 amount, uint256 fiatToTokenExchange, string iban);
    event OrderCancelled(uint256 id, string reason);
    event OrderPayed(uint256 id, address buyer, string paymentProof);
    event OrderReserved(uint256 id, address buyer);
    event OrderCompleted(uint256 id, address buyer, string paymentProof);
    event OrderReleased(uint256 id, string reason);

    struct Order {
        address seller;
        uint256 amount;
        uint256 fiatToTokenExchangeRate;
        string iban;
        address buyer;
        string paymentProof;
    }

    function _verifyAndRegisterAddress(address user) private {
        vm.startPrank(user);
        // If nullifier hash is 0, it will fail
        uint256 nullifierHash = 1;
        escrow.verifyAndRegister(address(0), 0, nullifierHash, [uint256(1),uint256(2),uint256(3),uint256(4),uint256(5),uint256(6),uint256(7),uint256(8)]);
        vm.stopPrank();
    }

    function setUp() public {
        vm.label(SELLER, "SELLER");
        vm.label(BUYER, "BUYER");
        vm.label(ARBITRATOR, "ARBITRATOR");
        vm.label(SELLER_2, "SELLER_2");
        vm.label(BUYER_2, "BUYER_2");
        vm.label(NOT_REGISTERED_SELLER, "NOT_REGISTERED_SELLER");
        vm.label(NOT_REGISTERED_BUYER, "NOT_REGISTERED_BUYER");
        token = new USDCMock();
        worldId = new MockWorldId();
        vm.startPrank(ARBITRATOR);
        escrow = new LeP2PEscrow(IWorldId(address(worldId)), "appId", "actionId", token);
        vm.stopPrank();
        allowedAmount = escrow.MAX_AMOUNT_NON_VERIFIED();
        token.mint(SELLER, INITIAL_CAPITAL);
        token.mint(SELLER_2, INITIAL_CAPITAL);
        vm.startPrank(SELLER);
        token.approve(address(escrow), type(uint256).max);
        vm.stopPrank();
        vm.startPrank(SELLER_2);
        token.approve(address(escrow), type(uint256).max);
        vm.stopPrank();
        // register seller and buyer
        _verifyAndRegisterAddress(SELLER);
        _verifyAndRegisterAddress(SELLER_2);
        _verifyAndRegisterAddress(BUYER);
    }

    function testCreateOrderOK() public {
        // GIVEN
        vm.expectEmit(true, true, true, true);
        emit OrderCreated(1, SELLER, allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        // WHEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        //THEN
        assertEq(token.balanceOf(SELLER), INITIAL_CAPITAL - allowedAmount);
        assertEq(token.balanceOf(address(escrow)), allowedAmount);
        assertEq(token.balanceOf(BUYER), 0);
        assertEq(escrow.nextOrderId(), 2);
        (address orderSeller, uint256 orederAmount, uint256 oderFiatToTokenExchange, string memory oderIban, address oderBuyer, string memory orderPaymentProof) = escrow.orders(1);
        assertEq(orderSeller, SELLER);
        assertEq(orederAmount, allowedAmount);
        assertEq(oderFiatToTokenExchange, FIAT_TO_TOKEN_EXCHANGE_RATE);
        assertEq(oderIban, IBAN);
        assertEq(oderBuyer, address(0));
        assertEq(bytes(orderPaymentProof).length, 0);
    }

    function testCreateOrderWithCancelAndLimitOK() public {
        // WHEN
        vm.expectEmit(true, true, true, true);
        emit OrderCreated(1, SELLER, allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(SELLER);
        vm.expectEmit(true, true, true, true);
        emit OrderCancelled(1, REASON);
        escrow.cancelOrderSeller(1, REASON);


        vm.expectEmit(true, true, true, true);
        emit OrderCreated(2, SELLER, allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        //THEN
        assertEq(token.balanceOf(SELLER), INITIAL_CAPITAL - allowedAmount);
        assertEq(token.balanceOf(address(escrow)), allowedAmount);
        assertEq(token.balanceOf(BUYER), 0);
        assertEq(escrow.nextOrderId(), 3);
        (address orderSeller, uint256 orederAmount, uint256 oderFiatToTokenExchange, string memory oderIban, address oderBuyer, string memory orderPaymentProof) = escrow.orders(2);
        assertEq(orderSeller, SELLER);
        assertEq(orederAmount, allowedAmount);
        assertEq(oderFiatToTokenExchange, FIAT_TO_TOKEN_EXCHANGE_RATE);
        assertEq(oderIban, IBAN);
        assertEq(oderBuyer, address(0));
        assertEq(bytes(orderPaymentProof).length, 0);
    }

    function testRevertCreateOrderAmount() public {
        // GIVEN
        uint256 amount = 0;

        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Amount must be greater than 0");
        escrow.createOrder(amount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);
    }

    function testRevertCreateOrderRate() public {
        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Exchange rate must be greater than 0");
        escrow.createOrder(allowedAmount, 0, IBAN);
    }

    function testRevertCreateOrderIBAN() public {
        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("IBAN must not be empty");
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, "");
    }

    function testRevertCreateOrderAmountTooBigUnverified() public {
        // GIVEN
        uint256 amount = allowedAmount + 1;

        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Address needs to be kycd for amounts greater than 1000");
        escrow.createOrder(amount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);
    }

    function testRevertCreateOrderAccumulationTooBigUnverified() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Address needs to be kycd for amounts greater than 1000");
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);
    }

    function testRevertCreateOrderNotRegistered() public {
        // WHEN + THEN
        vm.prank(NOT_REGISTERED_SELLER);
        vm.expectRevert("Address not registered");
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);
    }

    function testReserveOrderWithReleaseAndLimitOK() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.expectEmit(true, true, true, true);
        emit OrderReserved(1, BUYER);
        vm.prank(BUYER);
        escrow.reserveOrder(1);

        vm.expectEmit(true, true, true, true);
        emit OrderReleased(1, REASON);
        vm.prank(BUYER);
        escrow.releaseOrderBuyer(1, REASON);

        // WHEN
        vm.expectEmit(true, true, true, true);
        emit OrderReserved(1, BUYER);
        vm.prank(BUYER);
        escrow.reserveOrder(1);

        //THEN
        (, , , , address oderBuyer,) = escrow.orders(1);

        assertEq(oderBuyer, BUYER);
    }

    function testReserveOrderOK() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.expectEmit(true, true, true, true);
        emit OrderReserved(1, BUYER);

        // WHEN
        vm.prank(BUYER);
        escrow.reserveOrder(1);

        //THEN
        (, , , , address oderBuyer,) = escrow.orders(1);

        assertEq(oderBuyer, BUYER);
    }

    function testRevertReserveOrderOrderNotExistant() public {
        // WHEN + THEN
        vm.prank(BUYER);
        vm.expectRevert("Order does not exist");
        escrow.reserveOrder(1);
    }

    function testRevertReserveOrderBuyerPresent() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN + THEN
        vm.prank(BUYER);
        vm.expectRevert("Order already has a buyer");
        escrow.reserveOrder(1);
    }

    function testRevertReserveOrderAccumulationTooBigUnverified() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(SELLER_2);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN + THEN
        vm.prank(BUYER);
        vm.expectRevert("Address needs to be kycd for amounts greater than 1000");
        escrow.reserveOrder(2);
    }

    function testRevertReserveOrderUserNotRegistered() public {
        // WHEN + THEN
        vm.prank(NOT_REGISTERED_BUYER);
        vm.expectRevert("Address not registered");
        escrow.reserveOrder(1);
    }

    function testSubmitPaymentOK() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN
        vm.prank(BUYER);
        vm.expectEmit(true, true, true, true);
        emit OrderPayed(1, BUYER, IPFS_HASH);
        escrow.submitPayment(1, IPFS_HASH);

        //THEN
        (, , , , address oderBuyer,) = escrow.orders(1);

        assertEq(oderBuyer, BUYER);
    }

    function testRevertSubmitPaymentOrderNotExists() public {
        // WHEN + THEN
        vm.prank(BUYER);
        vm.expectRevert("Order does not exist");
        escrow.submitPayment(1, IPFS_HASH);
    }

    function testRevertSubmitPaymentNotBuyer() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN
        vm.prank(SELLER);
        vm.expectRevert("Not the buyer");
        escrow.submitPayment(1, IPFS_HASH);
    }

    function testConfirmOrderOK() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        vm.prank(BUYER);
        escrow.submitPayment(1, IPFS_HASH);

        // WHEN
        vm.prank(SELLER);
        vm.expectEmit(true, true, true, true);
        emit OrderCompleted(1, BUYER, IPFS_HASH);
        escrow.confirmOrder(1);

        //THEN
        (address oderSeller, , , , ,) = escrow.orders(1);

        assertEq(oderSeller, address(0));
        assertEq(token.balanceOf(SELLER), INITIAL_CAPITAL - allowedAmount);
        assertEq(token.balanceOf(address(escrow)), 0);
        assertEq(token.balanceOf(BUYER), allowedAmount);
    }

    function testRevertConfirmOrderOrderNotExist() public {
        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Order does not exist");
        escrow.confirmOrder(1);
    }

    function testRevertConfirmOrderNotSeller() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        vm.prank(BUYER);
        escrow.submitPayment(1, IPFS_HASH);

        // WHEN + THEN
        vm.prank(BUYER);
        vm.expectRevert("Not the seller");
        escrow.confirmOrder(1);
    }

    function testRevertConfirmOrderNoBuyer() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Order has no buyer");
        escrow.confirmOrder(1);
    }

    function testArbitrateCompleteOrderOK() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        vm.prank(BUYER);
        escrow.submitPayment(1, IPFS_HASH);

        // WHEN
        vm.prank(ARBITRATOR);
        vm.expectEmit(true, true, true, true);
        emit OrderCompleted(1, BUYER, IPFS_HASH);
        escrow.arbitrateCompleteOrder(1);

        //THEN
        (address oderSeller, , , , ,) = escrow.orders(1);

        assertEq(oderSeller, address(0));
        assertEq(token.balanceOf(SELLER), INITIAL_CAPITAL - allowedAmount);
        assertEq(token.balanceOf(address(escrow)), 0);
        assertEq(token.balanceOf(BUYER), allowedAmount);
    }

    function testRevertArbitrateCompleteOrderOrderNotExist() public {
        // WHEN + THEN
        vm.prank(ARBITRATOR);
        vm.expectRevert("Order does not exist");
        escrow.arbitrateCompleteOrder(1);
    }

    function testRevertArbitrateCompleteOrderNoBuyer() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        // WHEN + THEN
        vm.prank(ARBITRATOR);
        vm.expectRevert("Order has no buyer");
        escrow.arbitrateCompleteOrder(1);
    }

    function testRevertArbitrateCompleteOrderNotArbitrator() public {
        // GIVEN
        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        vm.prank(BUYER);
        escrow.submitPayment(1, IPFS_HASH);

        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Not an arbitrator");
        escrow.arbitrateCompleteOrder(1);
    }

    function testCancelOrderSellerOK() public {
        // GIVEN  
        uint256 orderId = 1;

        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        // WHEN
        vm.expectEmit(true, true, true, true);
        emit OrderCancelled(orderId, REASON);

        vm.prank(SELLER);
        escrow.cancelOrderSeller(orderId, REASON);

        //THEN
        assertEq(token.balanceOf(SELLER), INITIAL_CAPITAL);
        assertEq(token.balanceOf(address(escrow)), 0);
        assertEq(token.balanceOf(BUYER), 0);
        assertEq(escrow.nextOrderId(), 2);
        (address orderSeller, , , , , ) = escrow.orders(1);
        assertEq(orderSeller, address(0));
    }

    function testRevertCancelOrderSellerOrderNotExist() public {
        // GIVEN
        uint256 orderId = 1;

        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Order does not exist");
        escrow.cancelOrderSeller(orderId, REASON);
    }

    function testRevertCancelOrderSellerNotSeller() public {
        // GIVEN
        uint256 orderId = 1;

        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        // WHEN + THEN
        vm.prank(BUYER);
        vm.expectRevert("Not the seller");
        escrow.cancelOrderSeller(orderId, REASON);
    }

    function testRevertCancelOrderSellerNotSellerSide() public {
        // GIVEN
        uint256 orderId = 1;

        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN + THEN
        vm.prank(SELLER);
        vm.expectRevert("Order is on buyer side");
        escrow.cancelOrderSeller(orderId, REASON);
    }

    function testReleaseOrderBuyerOK() public {
        // GIVEN
        uint256 orderId = 1;

        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN
        vm.expectEmit(true, true, true, true);
        emit OrderReleased(orderId, REASON);

        vm.prank(BUYER);
        escrow.releaseOrderBuyer(orderId, REASON);

        //THEN
        (, , , , address orderBuyer, ) = escrow.orders(1);
        assertEq(orderBuyer, address(0));
    }

    function testRevertReleaseOrderBuyerOrderNotExist() public {
        // GIVEN
        uint256 orderId = 1;

        // WHEN
        vm.prank(BUYER);
        vm.expectRevert("Order does not exist");
        escrow.releaseOrderBuyer(orderId, REASON);
    }

    function testRevertReleaseOrderBuyerNotBuyer() public {
        // GIVEN
        uint256 orderId = 1;

        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN
        vm.prank(SELLER);
        vm.expectRevert("Not the buyer");
        escrow.releaseOrderBuyer(orderId, REASON);
    }

    function testReleaseOrderArbitratorOK() public {
        // GIVEN
        uint256 orderId = 1;

        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN
        vm.expectEmit(true, true, true, true);
        emit OrderReleased(orderId, REASON);

        vm.prank(ARBITRATOR);
        escrow.releaseOrderArbitrator(orderId, REASON);

        //THEN
        (, , , , address orderBuyer, ) = escrow.orders(1);
        assertEq(orderBuyer, address(0));
    }

    function testRevertReleaseOrderArbitratorOrderNotExist() public {
        // GIVEN
        uint256 orderId = 1;

        // WHEN
        vm.prank(BUYER);
        vm.expectRevert("Order does not exist");
        escrow.releaseOrderArbitrator(orderId, REASON);
    }

    function testRevertReleaseOrderArbitratorNotArbitrator() public {
        // GIVEN
        uint256 orderId = 1;

        vm.prank(SELLER);
        escrow.createOrder(allowedAmount, FIAT_TO_TOKEN_EXCHANGE_RATE, IBAN);

        vm.prank(BUYER);
        escrow.reserveOrder(1);

        // WHEN
        vm.prank(SELLER);
        vm.expectRevert("Not an arbitrator");
        escrow.releaseOrderArbitrator(orderId, REASON);
    }
}
