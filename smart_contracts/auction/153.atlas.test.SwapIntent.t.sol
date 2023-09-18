// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {BaseTest} from "./base/BaseTest.t.sol";
import {TxBuilder} from "../src/contracts/helpers/TxBuilder.sol";

import {ProtocolCall, UserCall, SearcherCall} from "../src/contracts/types/CallTypes.sol";
import {Verification} from "../src/contracts/types/VerificationTypes.sol";

import {SwapIntentController, SwapIntent, Condition} from "../src/contracts/intents-example/SwapIntent.sol";
import {SearcherBase} from "../src/contracts/searcher/SearcherBase.sol";

// QUESTIONS:

// Refactor Ideas:
// 1. Lots of bitwise operations explicitly coded in contracts - could be a helper lib thats more readable
// 2. helper is currently a V2Helper and shared from BaseTest. Should only be in Uni V2 related tests
// 3. Need a more generic helper for BaseTest
// 4. Gonna be lots of StackTooDeep errors. Maybe need a way to elegantly deal with that in BaseTest
// 5. Change metaFlashCall structure in SearcherBase - maybe virtual fn to be overridden, which hooks for checks
// 6. Maybe emit error msg or some other better UX for error if !valid in metacall()

// Doc Ideas:
// 1. Step by step instructions for building a metacall transaction (for internal testing, and integrating protocols)

// To Understand Better:
// 1. The lock system (and look for any gas optimizations / ways to reduce lock actions)


interface IUniV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SwapIntentTest is BaseTest {
    SwapIntentController public swapIntentController;
    TxBuilder public txBuilder;
    Sig public sig;

    ERC20 DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address DAI_ADDRESS = address(DAI);

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function setUp() public virtual override {
        BaseTest.setUp();

        // Creating new gov address (ERR-V49 OwnerActive if already registered with controller) 
        governancePK = 11112;
        governanceEOA = vm.addr(governancePK);

        // Deploy new SwapIntent Controller from new gov and initialize in Atlas
        vm.startPrank(governanceEOA);
        swapIntentController = new SwapIntentController(address(escrow));        
        atlas.initializeGovernance(address(swapIntentController));
        atlas.integrateProtocol(address(swapIntentController), address(swapIntentController));
        vm.stopPrank();

        txBuilder = new TxBuilder({
            protocolControl: address(swapIntentController),
            escrowAddress: address(escrow),
            atlasAddress: address(atlas)
        });

        
    }

    function testAtlasSwapIntentWithBasicRFQ() public {
        // Swap 10 WETH for 20 DAI

        UserCondition userCondition = new UserCondition();

        Condition[] memory conditions = new Condition[](2);
        conditions[0] = Condition({
            antecedent: address(userCondition),
            context: abi.encodeWithSelector(UserCondition.isLessThanFive.selector, 3)
        });
        conditions[1] = Condition({
            antecedent: address(userCondition),
            context: abi.encodeWithSelector(UserCondition.isLessThanFive.selector, 4)
        });

        SwapIntent memory swapIntent = SwapIntent({
            tokenUserBuys: DAI_ADDRESS,
            amountUserBuys: 20e18,
            tokenUserSells: WETH_ADDRESS,
            amountUserSells: 10e18,
            auctionBaseCurrency: address(0),
            searcherMustReimburseGas: false,
            conditions: conditions
        });

        // Searcher deploys the RFQ searcher contract (defined at bottom of this file)
        vm.startPrank(searcherOneEOA);
        SimpleRFQSearcher rfqSearcher = new SimpleRFQSearcher(address(atlas));
        atlas.deposit{value: 1e18}(searcherOneEOA);
        vm.stopPrank();

        // Give 20 DAI to RFQ searcher contract
        deal(DAI_ADDRESS, address(rfqSearcher), swapIntent.amountUserBuys);
        assertEq(DAI.balanceOf(address(rfqSearcher)), swapIntent.amountUserBuys, "Did not give enough DAI to searcher");

        // Input params for Atlas.metacall() - will be populated below
        ProtocolCall memory protocolCall = txBuilder.getProtocolCall();
        UserCall memory userCall;
        SearcherCall[] memory searcherCalls = new SearcherCall[](1);
        Verification memory verification;

        vm.startPrank(userEOA);
        address executionEnvironment = atlas.createExecutionEnvironment(protocolCall);
        vm.stopPrank();
        vm.label(address(executionEnvironment), "EXECUTION ENV");

        // userCallData is used in delegatecall from exec env to control, calling stagingCall
        // first 4 bytes are "userSelector" param in stagingCall in ProtocolControl - swap() selector
        // rest of data is "userData" param
        
        // swap(SwapIntent calldata) selector = 0x98434997
        bytes memory userCallData = abi.encodeWithSelector(SwapIntentController.swap.selector, swapIntent);

        // Builds the metaTx and to parts of userCall, signature still to be set
        userCall = txBuilder.buildUserCall({
            from: userEOA, // NOTE: Would from ever not be user?
            to: address(swapIntentController),
            maxFeePerGas: tx.gasprice + 1, // TODO update
            value: 0,
            data: userCallData
        });

        // User signs the userCall
        (sig.v, sig.r, sig.s) = vm.sign(userPK, atlas.getUserCallPayload(userCall));
        userCall.signature = abi.encodePacked(sig.r, sig.s, sig.v);

        // Build searcher calldata (function selector on searcher contract and its params)
        bytes memory searcherCallData = abi.encodeWithSelector(
            SimpleRFQSearcher.fulfillRFQ.selector, 
            swapIntent,
            executionEnvironment
        );

        // Builds the SearcherCall
        searcherCalls[0] = txBuilder.buildSearcherCall({
            userCall: userCall,
            protocolCall: protocolCall,
            searcherCallData: searcherCallData,
            searcherEOA: searcherOneEOA,
            searcherContract: address(rfqSearcher),
            bidAmount: 1e18
        });

        // Searcher signs the searcherCall
        (sig.v, sig.r, sig.s) = vm.sign(searcherOnePK, atlas.getSearcherPayload(searcherCalls[0].metaTx));
        searcherCalls[0].signature = abi.encodePacked(sig.r, sig.s, sig.v);

        // Frontend creates verification calldata after seeing rest of data
        verification = txBuilder.buildVerification(governanceEOA, protocolCall, userCall, searcherCalls);

        // Frontend signs the verification payload
        (sig.v, sig.r, sig.s) = vm.sign(governancePK, atlas.getVerificationPayload(verification));
        verification.signature = abi.encodePacked(sig.r, sig.s, sig.v);

        // Check user token balances before
        uint256 userWethBalanceBefore = WETH.balanceOf(userEOA);
        uint256 userDaiBalanceBefore = DAI.balanceOf(userEOA);

        vm.prank(userEOA); // Burn all users WETH except 10 so logs are more readable
        WETH.transfer(address(1), userWethBalanceBefore - swapIntent.amountUserSells);
        userWethBalanceBefore = WETH.balanceOf(userEOA);

        assertTrue(userWethBalanceBefore >= swapIntent.amountUserSells, "Not enough starting WETH");

        console.log("\nBEFORE METACALL");
        console.log("User WETH balance", WETH.balanceOf(userEOA));
        console.log("User DAI balance", DAI.balanceOf(userEOA));
        console.log("Searcher WETH balance", WETH.balanceOf(address(rfqSearcher)));
        console.log("Searcher DAI balance", DAI.balanceOf(address(rfqSearcher)));

        vm.startPrank(userEOA);
        
        assertFalse(atlas.testUserCall(userCall), "UserCall tested true");
        
        WETH.approve(address(atlas), swapIntent.amountUserSells);

        assertTrue(atlas.testUserCall(userCall), "UserCall tested true");
        assertTrue(atlas.testUserCall(userCall.metaTx), "UserMetaTx tested true");


        // NOTE: Should metacall return something? Feels like a lot of data you might want to know about the tx
        atlas.metacall({
            protocolCall: protocolCall,
            userCall: userCall,
            searcherCalls: searcherCalls,
            verification: verification
        });
        vm.stopPrank();

        console.log("\nAFTER METACALL");
        console.log("User WETH balance", WETH.balanceOf(userEOA));
        console.log("User DAI balance", DAI.balanceOf(userEOA));
        console.log("Searcher WETH balance", WETH.balanceOf(address(rfqSearcher)));
        console.log("Searcher DAI balance", DAI.balanceOf(address(rfqSearcher)));

        // Check user token balances after
        assertEq(WETH.balanceOf(userEOA), userWethBalanceBefore - swapIntent.amountUserSells, "Did not spend enough WETH");
        assertEq(DAI.balanceOf(userEOA), userDaiBalanceBefore + swapIntent.amountUserBuys, "Did not receive enough DAI");
    }

    function testAtlasSwapIntentWithUniswapSearcher() public {
        // Swap 10 WETH for 20 DAI
        Condition[] memory conditions;

        SwapIntent memory swapIntent = SwapIntent({
            tokenUserBuys: DAI_ADDRESS,
            amountUserBuys: 20e18,
            tokenUserSells: WETH_ADDRESS,
            amountUserSells: 10e18,
            auctionBaseCurrency: address(0),
            searcherMustReimburseGas: false,
            conditions: conditions
        });

        // Searcher deploys the RFQ searcher contract (defined at bottom of this file)
        vm.startPrank(searcherOneEOA);
        UniswapIntentSearcher uniswapSearcher = new UniswapIntentSearcher(address(atlas));
        deal(WETH_ADDRESS, address(uniswapSearcher), 1e18); // 1 WETH to searcher to pay bid
        vm.stopPrank();

        // Input params for Atlas.metacall() - will be populated below
        ProtocolCall memory protocolCall = txBuilder.getProtocolCall();
        UserCall memory userCall;
        SearcherCall[] memory searcherCalls = new SearcherCall[](1);
        Verification memory verification;

        vm.startPrank(userEOA);
        address executionEnvironment = atlas.createExecutionEnvironment(protocolCall);
        vm.stopPrank();
        vm.label(address(executionEnvironment), "EXECUTION ENV");

        // userCallData is used in delegatecall from exec env to control, calling stagingCall
        // first 4 bytes are "userSelector" param in stagingCall in ProtocolControl - swap() selector
        // rest of data is "userData" param
        
        // swap(SwapIntent calldata) selector = 0x98434997
        bytes memory userCallData = abi.encodeWithSelector(SwapIntentController.swap.selector, swapIntent);

        // Builds the metaTx and to parts of userCall, signature still to be set
        userCall = txBuilder.buildUserCall({
            from: userEOA, // NOTE: Would from ever not be user?
            to: address(swapIntentController),
            maxFeePerGas: tx.gasprice + 1, // TODO update
            value: 0,
            data: userCallData
        });

        // User signs the userCall
        (sig.v, sig.r, sig.s) = vm.sign(userPK, atlas.getUserCallPayload(userCall));
        userCall.signature = abi.encodePacked(sig.r, sig.s, sig.v);

        // Build searcher calldata (function selector on searcher contract and its params)
        bytes memory searcherCallData = abi.encodeWithSelector(
            UniswapIntentSearcher.fulfillWithSwap.selector, 
            swapIntent,
            executionEnvironment
        );

        // Builds the SearcherCall
        searcherCalls[0] = txBuilder.buildSearcherCall({
            userCall: userCall,
            protocolCall: protocolCall,
            searcherCallData: searcherCallData,
            searcherEOA: searcherOneEOA,
            searcherContract: address(uniswapSearcher),
            bidAmount: 1e18
        });

        // Searcher signs the searcherCall
        (sig.v, sig.r, sig.s) = vm.sign(searcherOnePK, atlas.getSearcherPayload(searcherCalls[0].metaTx));
        searcherCalls[0].signature = abi.encodePacked(sig.r, sig.s, sig.v);

        // Frontend creates verification calldata after seeing rest of data
        verification = txBuilder.buildVerification(governanceEOA, protocolCall, userCall, searcherCalls);

        // Frontend signs the verification payload
        (sig.v, sig.r, sig.s) = vm.sign(governancePK, atlas.getVerificationPayload(verification));
        verification.signature = abi.encodePacked(sig.r, sig.s, sig.v);

        // Check user token balances before
        uint256 userWethBalanceBefore = WETH.balanceOf(userEOA);
        uint256 userDaiBalanceBefore = DAI.balanceOf(userEOA);

        vm.prank(userEOA); // Burn all users WETH except 10 so logs are more readable
        WETH.transfer(address(1), userWethBalanceBefore - swapIntent.amountUserSells);
        userWethBalanceBefore = WETH.balanceOf(userEOA);

        assertTrue(userWethBalanceBefore >= swapIntent.amountUserSells, "Not enough starting WETH");

        console.log("\nBEFORE METACALL");
        console.log("User WETH balance", WETH.balanceOf(userEOA));
        console.log("User DAI balance", DAI.balanceOf(userEOA));
        console.log("Searcher WETH balance", WETH.balanceOf(address(uniswapSearcher)));
        console.log("Searcher DAI balance", DAI.balanceOf(address(uniswapSearcher)));

        vm.startPrank(userEOA);
        
        assertFalse(atlas.testUserCall(userCall), "UserCall tested true");
        
        WETH.approve(address(atlas), swapIntent.amountUserSells);

        assertTrue(atlas.testUserCall(userCall), "UserCall tested true");
        assertTrue(atlas.testUserCall(userCall.metaTx), "UserMetaTx tested true");

        // Check searcher does NOT have DAI - it must use Uniswap to get it during metacall
        assertEq(DAI.balanceOf(address(uniswapSearcher)), 0, "Searcher has DAI before metacall");


        // NOTE: Should metacall return something? Feels like a lot of data you might want to know about the tx
        atlas.metacall({
            protocolCall: protocolCall,
            userCall: userCall,
            searcherCalls: searcherCalls,
            verification: verification
        });
        vm.stopPrank();

        console.log("\nAFTER METACALL");
        console.log("User WETH balance", WETH.balanceOf(userEOA));
        console.log("User DAI balance", DAI.balanceOf(userEOA));
        console.log("Searcher WETH balance", WETH.balanceOf(address(uniswapSearcher)));
        console.log("Searcher DAI balance", DAI.balanceOf(address(uniswapSearcher)));

        // Check user token balances after
        assertEq(WETH.balanceOf(userEOA), userWethBalanceBefore - swapIntent.amountUserSells, "Did not spend enough WETH");
        assertEq(DAI.balanceOf(userEOA), userDaiBalanceBefore + swapIntent.amountUserBuys, "Did not receive enough DAI");
    }
}

// This searcher magically has the tokens needed to fulfil the user's swap.
// This might involve an offchain RFQ system
contract SimpleRFQSearcher is SearcherBase {
    constructor(address atlas) SearcherBase(atlas, msg.sender) {}

    function fulfillRFQ(
        SwapIntent calldata swapIntent,
        address executionEnvironment
    ) public {
        require(ERC20(swapIntent.tokenUserSells).balanceOf(address(this)) >= swapIntent.amountUserSells, "Did not receive enough tokenIn");
        require(ERC20(swapIntent.tokenUserBuys).balanceOf(address(this)) >= swapIntent.amountUserBuys, "Not enough tokenOut to fulfill");
        ERC20(swapIntent.tokenUserBuys).transfer(executionEnvironment, swapIntent.amountUserBuys);
    }

    fallback() external payable {}
    receive() external payable {}
}

contract UniswapIntentSearcher is SearcherBase {
    IUniV2Router02 router = IUniV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(address atlas) SearcherBase(atlas, msg.sender) {}

    function fulfillWithSwap(
        SwapIntent calldata swapIntent,
        address executionEnvironment
    ) public onlySelf {
        // Checks recieved expected tokens from Atlas on behalf of user to swap
        require(ERC20(swapIntent.tokenUserSells).balanceOf(address(this)) >= swapIntent.amountUserSells, "Did not receive enough tokenIn");

        address[] memory path = new address[](2);
        path[0] = swapIntent.tokenUserSells;
        path[1] = swapIntent.tokenUserBuys;

        // Attempt to sell all tokens for as many as possible of tokenUserBuys
        ERC20(swapIntent.tokenUserSells).approve(address(router), swapIntent.amountUserSells);
        router.swapExactTokensForTokens({
            amountIn: swapIntent.amountUserSells,
            amountOutMin: swapIntent.amountUserBuys, // will revert here if not enough to fulfill intent
            path: path,
            to: address(this),
            deadline: block.timestamp
        });

        // Send min tokens back to user to fulfill intent, rest are profit for searcher
        ERC20(swapIntent.tokenUserBuys).transfer(executionEnvironment, swapIntent.amountUserBuys);
    }

    // This ensures a function can only be called through metaFlashCall
    // which includes security checks to work safely with Atlas
    modifier onlySelf() {
        require(msg.sender == address(this), "Not called via metaFlashCall");
        _;
    }

    fallback() external payable {}
    receive() external payable {}
}

contract UserCondition {
    bool valid = true;

    function enable() external {
        valid = true;
    }

    function disable() external {
        valid = false;
    }

    function isLessThanFive(uint256 n) external view returns (bool) {
        return valid && n < 5;
    }
}