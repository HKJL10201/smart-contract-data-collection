// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Registry.sol";
import "../src/Marketplace.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    constructor() ERC721("NFT", "NFT") {}

    function safeMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId, "");
    }
}

contract NFT721 is ERC721, ERC2981, Ownable {
    constructor() ERC721("NFT721", "NFT721") {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC2981, ERC721) returns (bool) {
        return
            ERC2981.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    function safeMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId, "");
    }
}

contract NFT1155 is ERC1155, ERC2981, Ownable {
    constructor() ERC1155("baseURI") {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, ERC2981) returns (bool) {
        return
            ERC2981.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }
}

contract MockCurrency is ERC20, Test {
    address addressA = vm.addr(1);

    constructor() ERC20("Mock Currency", "MC") {
        _mint(address(addressA), 100_000 * 10 ** 18);
    }
}

contract MarketplaceTest is Test {
    Registry registry;
    Marketplace marketPlace;
    NFT nft;
    NFT721 nft721;
    NFT1155 nft1155;
    MockCurrency mockCurrency;

    address addressA = vm.addr(1);
    address addressB = vm.addr(2);
    address addressC = vm.addr(3);
    address addressD = vm.addr(4);

    event SaleCreated(
        uint256 indexed id,
        address indexed nftAddress,
        uint256 indexed nftID
    );
    event SaleCancelled(uint256 indexed saleId);
    event Purchase(
        uint256 indexed saleId,
        address indexed purchaser,
        address indexed recipient
    );
    event ClaimSaleNFTs(
        uint256 indexed id,
        address indexed owner,
        uint256 indexed amount
    );
    event ClaimFunds(
        address indexed accountOf,
        address indexed tokenAddress,
        uint256 indexed newBalance
    );

    event BidPlaced(uint256 indexed auctionId, uint256 totalAmount);

    struct Bid {
        uint256 amount;
        uint256 timestamp;
    }

    function setUp() public {
        // create contract instance
        registry = new Registry();
        marketPlace = new Marketplace(address(registry));
        nft721 = new NFT721();
        nft1155 = new NFT1155();
        mockCurrency = new MockCurrency();

        // approve nft contracts and currency
        registry.setContractStatus(address(marketPlace), true);
        registry.setContractStatus(address(nft721), true);
        registry.setContractStatus(address(nft1155), true);
        registry.setCurrencyStatus(address(mockCurrency), true);
    }

    function testCreateSaleERC721() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);

        // emit the SaleCreated event correctly
        vm.expectEmit(true, true, true, true);
        emit SaleCreated(1, address(nft721), 1);

        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        vm.stopPrank();

        // save sale info correctly
        (
            uint128 nftId,
            bool isERC721,
            address nftAddress,
            address owner,
            address currency,
            uint256 amount,
            uint256 purchased,
            uint256 startTime,
            uint256 endTime,
            uint256 price
        ) = marketPlace.sales(1);

        assertEq(isERC721, true);
        assertEq(nftAddress, address(nft721));
        assertEq(nftId, 1);
        assertEq(owner, address(addressA));
        assertEq(amount, 1);
        assertEq(purchased, 0);
        assertEq(startTime, block.timestamp);
        assertEq(endTime, block.timestamp + 3 days);
        assertEq(price, 100);
        assertEq(currency, address(mockCurrency));

        // transfer nft to the platform
        assertEq(nft721.balanceOf(address(marketPlace)), 1);
        assertEq(nft721.ownerOf(1), address(marketPlace));
        assertEq(nft721.balanceOf(address(addressA)), 0);
    }

    function testCreateSaleERC1155() public {
        nft1155.mint(addressB, 1, 10);
        vm.startPrank(addressB);
        nft1155.setApprovalForAll(address(marketPlace), true);

        // emit the SaleCreated event correctly
        vm.expectEmit(true, true, true, true);
        emit SaleCreated(1, address(nft1155), 1);

        marketPlace.createSale({
            isERC721: false,
            nftAddress: address(nft1155),
            nftId: 1,
            amount: 5,
            startTime: block.timestamp,
            endTime: block.timestamp + 4 days,
            price: 200,
            currency: address(mockCurrency)
        });
        vm.stopPrank();

        // save sale info correctly
        (
            uint128 nftId,
            bool isERC721,
            address nftAddress,
            address owner,
            address currency,
            uint256 amount,
            uint256 purchased,
            uint256 startTime,
            uint256 endTime,
            uint256 price
        ) = marketPlace.sales(1);

        assertEq(isERC721, false);
        assertEq(nftAddress, address(nft1155));
        assertEq(nftId, 1);
        assertEq(owner, address(addressB));
        assertEq(amount, 5);
        assertEq(purchased, 0);
        assertEq(startTime, block.timestamp);
        assertEq(endTime, block.timestamp + 4 days);
        assertEq(price, 200);
        assertEq(currency, address(mockCurrency));

        // transfer nft to the platform
        assertEq(nft1155.balanceOf(address(marketPlace), 1), 5);
        assertEq(nft1155.balanceOf(address(addressB), 1), 5);
    }

    function testCreateSaleFailsNotApprovedContract() public {
        registry.setContractStatus(address(nft721), false);
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);

        vm.expectRevert(bytes4(keccak256("NFTContractIsNotApproved()")));
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        vm.stopPrank();
    }

    function testCreateSaleFailsContractDeptecated() public {
        registry.setContractStatus(address(marketPlace), false);
        nft721.safeMint(addressA, 2);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 2);

        vm.expectRevert(bytes4(keccak256("ContractIsDeprecated()")));
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 2,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 5 days,
            price: 300,
            currency: address(mockCurrency)
        });
        vm.stopPrank();
    }

    function testCreateSaleFailsNotSupportedCurrency() public {
        registry.setCurrencyStatus(address(mockCurrency), false);
        nft721.safeMint(addressA, 2);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 2);

        vm.expectRevert(bytes4(keccak256("CurrencyIsNotSupported()")));
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 2,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 5 days,
            price: 300,
            currency: address(mockCurrency)
        });
        vm.stopPrank();
    }

    function testCreateSaleFailsContractNotSupportERC2981() public {
        nft = new NFT();
        registry.setContractStatus(address(nft), true);
        nft.safeMint(addressA, 2);
        vm.startPrank(addressA);
        nft.approve(address(marketPlace), 2);

        vm.expectRevert(bytes4(keccak256("ContractMustSupportERC2981()")));
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft),
            nftId: 2,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 5 days,
            price: 300,
            currency: address(mockCurrency)
        });
        vm.stopPrank();
    }

    function testCreateSaleFailsInvalidStartEndTime() public {
        nft721.safeMint(addressA, 2);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 2);

        vm.expectRevert(
            bytes4(keccak256("EndTimeMustBeGreaterThanStartTime()"))
        );
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 2,
            amount: 1,
            startTime: block.timestamp + 10 days,
            endTime: block.timestamp + 5 days,
            price: 300,
            currency: address(mockCurrency)
        });
        vm.stopPrank();
    }

    function testCreateSaleFailSellMoreThanOneERC721() public {
        nft721.safeMint(addressA, 2);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 2);

        vm.expectRevert(bytes4(keccak256("CanOnlySellOneNFT()")));
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 2,
            amount: 2,
            startTime: block.timestamp,
            endTime: block.timestamp + 5 days,
            price: 300,
            currency: address(mockCurrency)
        });
        vm.stopPrank();
    }

    function testBuyERC721() public {
        // create a sale
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        // buy nft, emit the correct Purchase event
        vm.startPrank(addressB);
        mockCurrency.approve(address(marketPlace), 100);
        vm.expectEmit(true, true, true, true);
        emit Purchase(1, address(addressB), address(addressB));
        marketPlace.buy({
            saleId: 1,
            recipient: address(addressB),
            amountToBuy: 1,
            amountFromBalance: 0
        });

        // send the nft cost to the platform
        uint256 marketPlaceBalance = mockCurrency.balanceOf(
            address(marketPlace)
        );
        assertEq(marketPlaceBalance, 100);

        // add system fee to systemWallet balance
        (address systemWallet, uint256 fee) = registry.feeInfo(100);
        uint256 systemBalance = marketPlace.claimableFunds(
            systemWallet,
            address(mockCurrency)
        );
        assertEq(fee, systemBalance);

        // add seller gains to seller balance
        uint256 sellerBalance = marketPlace.claimableFunds(
            address(addressA),
            address(mockCurrency)
        );
        assertEq(sellerBalance, 100 - fee);

        // update sale info
        (
            uint128 nftId,
            bool isERC721,
            address nftAddress,
            address owner,
            address currency,
            uint256 amount,
            uint256 purchased,
            uint256 startTime,
            uint256 endTime,
            uint256 price
        ) = marketPlace.sales(1);
        assertEq(purchased, 1);
        assertEq(marketPlace.purchased(1, address(addressB)), 1);

        // send the nft to the buyer
        assertEq(nft721.balanceOf(address(marketPlace)), 0);
        assertEq(nft721.ownerOf(1), address(addressB));
        assertEq(nft721.balanceOf(address(addressB)), 1);
    }

    function testBuyERC1155() public {
        // create a sale
        nft1155.mint(addressA, 1, 10);
        vm.startPrank(addressA);
        nft1155.setApprovalForAll(address(marketPlace), true);

        // emit the SaleCreated event correctly
        vm.expectEmit(true, true, true, true);
        emit SaleCreated(1, address(nft1155), 1);

        marketPlace.createSale({
            isERC721: false,
            nftAddress: address(nft1155),
            nftId: 1,
            amount: 5,
            startTime: block.timestamp,
            endTime: block.timestamp + 4 days,
            price: 200,
            currency: address(mockCurrency)
        });
        // vm.stopPrank();

        // buy nft, emit the correct Purchase event
        mockCurrency.approve(address(marketPlace), 600);
        vm.expectEmit(true, true, true, true);
        emit Purchase(1, address(addressA), address(addressB));
        marketPlace.buy({
            saleId: 1,
            recipient: address(addressB),
            amountToBuy: 3,
            amountFromBalance: 0
        });
        vm.stopPrank();

        // send the nft cost to the platform
        uint256 marketPlaceBalance = mockCurrency.balanceOf(
            address(marketPlace)
        );
        assertEq(marketPlaceBalance, 600);

        // add system fee to systemWallet balance
        (address systemWallet, uint256 fee) = registry.feeInfo(600);
        uint256 systemBalance = marketPlace.claimableFunds(
            systemWallet,
            address(mockCurrency)
        );
        assertEq(fee, systemBalance);

        // add seller gains to seller balance
        uint256 sellerBalance = marketPlace.claimableFunds(
            address(addressA),
            address(mockCurrency)
        );
        assertEq(sellerBalance, 600 - fee);

        // update sale info
        (
            uint128 nftId,
            bool isERC721,
            address nftAddress,
            address owner,
            address currency,
            uint256 amount,
            uint256 purchased,
            uint256 startTime,
            uint256 endTime,
            uint256 price
        ) = marketPlace.sales(1);
        assertEq(purchased, 3);
        assertEq(marketPlace.purchased(1, address(addressA)), 3);

        // send the nft to the buyer
        assertEq(nft1155.balanceOf(address(marketPlace), 1), 2);
        assertEq(nft1155.balanceOf(address(addressB), 1), 3);
    }

    function testBuyFailContractDeprecated() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        registry.setContractStatus(address(marketPlace), false);
        vm.startPrank(address(addressA));
        mockCurrency.approve(address(marketPlace), 100);
        vm.expectRevert(bytes4(keccak256("ContractIsDeprecated()")));
        marketPlace.buy({
            saleId: 1,
            recipient: address(addressB),
            amountToBuy: 1,
            amountFromBalance: 0
        });
    }

    function testBuyFailSaleNotActive() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);

        mockCurrency.approve(address(marketPlace), 200);
        marketPlace.buy({
            saleId: 1,
            recipient: address(addressB),
            amountToBuy: 1,
            amountFromBalance: 0
        });

        vm.expectRevert(bytes4(keccak256("SaleIsNotActive()")));
        marketPlace.buy({
            saleId: 1,
            recipient: address(addressB),
            amountToBuy: 1,
            amountFromBalance: 0
        });
    }

    function testBuyFailNotEnoughStock() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        mockCurrency.approve(address(marketPlace), 200);

        vm.expectRevert(bytes4(keccak256("NotEnoughStock()")));
        marketPlace.buy({
            saleId: 1,
            recipient: address(addressB),
            amountToBuy: 2,
            amountFromBalance: 0
        });
    }

    function testBuyFailNotEnoughBalance() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        mockCurrency.approve(address(marketPlace), 200);

        vm.expectRevert(bytes4(keccak256("NotEnoughBalance()")));
        marketPlace.buy({
            saleId: 1,
            recipient: address(addressB),
            amountToBuy: 1,
            amountFromBalance: 50
        });
    }

    function testClaimSaleNftsERC721() public {
        // create a sale
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });

        // claim nft(s) and emit the ClaimSaleNFTs event correctly
        skip(4 days);
        vm.expectEmit(true, true, true, true);
        emit ClaimSaleNFTs(1, address(addressA), 1);
        marketPlace.claimSaleNfts(1);

        // update purchased info correctly
        (
            uint128 nftId,
            bool isERC721,
            address nftAddress,
            address owner,
            address currency,
            uint256 amount,
            uint256 purchased,
            uint256 startTime,
            uint256 endTime,
            uint256 price
        ) = marketPlace.sales(1);
        assertEq(purchased, 1);

        // send nft(s) back to the seller correctly
        assertEq(nft721.balanceOf(address(marketPlace)), 0);
        assertEq(nft721.ownerOf(1), address(address(addressA)));
        assertEq(nft721.balanceOf(address(addressA)), 1);
    }

    function testClaimSaleNftsERC1155() public {
        // create a sale
        nft1155.mint(addressA, 1, 10);
        vm.startPrank(addressA);
        nft1155.setApprovalForAll(address(marketPlace), true);
        marketPlace.createSale({
            isERC721: false,
            nftAddress: address(nft1155),
            nftId: 1,
            amount: 3,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });

        assertEq(nft1155.balanceOf(address(marketPlace), 1), 3);
        assertEq(nft1155.balanceOf(address(addressA), 1), 7);

        // claim nft(s) and emit the ClaimSaleNfts event correctly
        skip(4 days);
        vm.expectEmit(true, true, true, true);
        emit ClaimSaleNFTs(1, address(addressA), 3);
        marketPlace.claimSaleNfts(1);

        // update purchased info correctly
        (
            uint128 nftId,
            bool isERC721,
            address nftAddress,
            address owner,
            address currency,
            uint256 amount,
            uint256 purchased,
            uint256 startTime,
            uint256 endTime,
            uint256 price
        ) = marketPlace.sales(1);
        assertEq(purchased, 3);

        // send nft(s) back to the seller correctly
        assertEq(nft1155.balanceOf(address(marketPlace), 1), 0);
        assertEq(nft1155.balanceOf(address(addressA), 1), 10);
    }

    function testClaimSaleNftsFailSaleNotClosed() public {
        // create a sale
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });

        // claim nft(s)
        vm.expectRevert(bytes4(keccak256("SaleIsNotClosed()")));
        marketPlace.claimSaleNfts(1);
    }

    function testClaimSaleNftsFailNotNftOwner() public {
        // create a sale
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        vm.stopPrank();

        // claim nft(s)
        skip(4 days);
        vm.expectRevert(bytes4(keccak256("OnlyNFTOwnerCanClaim()")));
        marketPlace.claimSaleNfts(1);
    }

    function testClaimSaleNftsFailAlreadySoldOrClaimed() public {
        // create a sale
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });

        // claim nft(s)
        skip(4 days);
        marketPlace.claimSaleNfts(1);

        // claim nft(s) again
        vm.expectRevert(bytes4(keccak256("StockAlreadySoldOrClaimed()")));
        marketPlace.claimSaleNfts(1);
    }

    function testClaimFunds() public {
        // create a sale
        nft721.safeMint(addressC, 1);
        vm.startPrank(addressC);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });
        vm.stopPrank();

        // buy nft
        vm.startPrank(addressA);
        mockCurrency.approve(address(marketPlace), 100);
        marketPlace.buy({
            saleId: 1,
            recipient: address(addressA),
            amountToBuy: 1,
            amountFromBalance: 0
        });
        vm.stopPrank();

        // emit the ClaimFunds event correctly
        uint256 sellerBalanceBeforeClaimed = marketPlace.claimableFunds(
            address(addressC),
            address(mockCurrency)
        );
        vm.startPrank(address(addressC));
        vm.expectEmit(true, true, true, true);
        emit ClaimFunds(
            address(addressC),
            address(mockCurrency),
            sellerBalanceBeforeClaimed
        );
        marketPlace.claimFunds(address(mockCurrency));

        uint256 sellerBalanceAfterClaimed = marketPlace.claimableFunds(
            address(addressC),
            address(mockCurrency)
        );

        assertEq(
            mockCurrency.balanceOf(address(addressC)),
            sellerBalanceBeforeClaimed
        );
        assertEq(sellerBalanceAfterClaimed, 0);
    }

    function testClaimedFundFailNothingToClaim() public {
        vm.expectRevert(bytes4(keccak256("NothingToClaim()")));
        marketPlace.claimFunds(address(mockCurrency));
    }

    function testCancelSale() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);

        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });

        // emit the SaleCancelled event correctly
        vm.expectEmit(true, true, true, true);
        emit SaleCancelled(1);
        marketPlace.cancelSale(1);

        assertEq(marketPlace.cancelledSale(1), true);
        assertEq(marketPlace.getSaleStatus(1), "CANCELLED");
    }

    function testCancelSaleFailOnlyOwnerOrCreator() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);

        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });

        vm.stopPrank();
        vm.prank(address(addressD));
        vm.expectRevert(bytes4(keccak256("OnlyOwnerOrSaleCreator()")));
        marketPlace.cancelSale(1);
    }

    function testCancelSaleFailNotActiveOrPending() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);

        marketPlace.createSale({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            amount: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            price: 100,
            currency: address(mockCurrency)
        });

        marketPlace.cancelSale(1);
        vm.expectRevert(bytes4(keccak256("SaleMustBeActiveOrPending()")));
        marketPlace.cancelSale(1);
        vm.stopPrank();
    }

    function testCreateAuctionERC721() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);

        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 100,
            currency: address(mockCurrency)
        });

        // send nft(s) to the marketplace correctly
        assertEq(nft721.balanceOf(address(marketPlace)), 1);
        assertEq(nft721.ownerOf(1), address(address(marketPlace)));
        assertEq(nft721.balanceOf(address(addressA)), 0);

        // save auction info correctly
        (
            uint128 id,
            uint128 nftId,
            bool isERC721,
            address nftAddress,
            address owner,
            address currency,
            uint256 startTime,
            uint256 endTime,
            uint256 reservePrice
        ) = marketPlace.auctions(1);

        assertEq(isERC721, true);
        assertEq(id, 1);
        assertEq(owner, address(addressA));
        assertEq(nftAddress, address(nft721));
        assertEq(nftId, 1);
        assertEq(startTime, block.timestamp);
        assertEq(endTime, block.timestamp + 3 days);
        assertEq(reservePrice, 100);
        assertEq(currency, address(mockCurrency));
    }

    function testCreateAuctionERC1155() public {
        nft1155.mint(addressA, 1, 10);
        vm.startPrank(addressA);
        nft1155.setApprovalForAll(address(marketPlace), true);

        marketPlace.createAuction({
            isERC721: false,
            nftAddress: address(nft1155),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 100,
            currency: address(mockCurrency)
        });

        // send nft(s) to the marketplace correctly
        assertEq(nft1155.balanceOf(address(marketPlace), 1), 1);
        assertEq(nft1155.balanceOf(address(addressA), 1), 9);

        // save auction info correctly
        (
            uint128 id,
            uint128 nftId,
            bool isERC721,
            address nftAddress,
            address owner,
            address currency,
            uint256 startTime,
            uint256 endTime,
            uint256 reservePrice
        ) = marketPlace.auctions(1);

        assertEq(isERC721, false);
        assertEq(id, 1);
        assertEq(owner, address(addressA));
        assertEq(nftAddress, address(nft1155));
        assertEq(nftId, 1);
        assertEq(startTime, block.timestamp);
        assertEq(endTime, block.timestamp + 3 days);
        assertEq(reservePrice, 100);
        assertEq(currency, address(mockCurrency));
    }

    function testBid() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        vm.startPrank(addressB);
        mockCurrency.approve(address(marketPlace), 200);
        // emit the SaleCancelled event correctly
        vm.expectEmit(true, true, true, true);
        emit BidPlaced(1, 200);
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 0,
            externalFunds: 200
        });

        // save the correct bid info
        assertEq(marketPlace.escrow(address(mockCurrency)), 200);
        (uint256 amount, uint256 timestamp) = marketPlace.bids(
            1,
            address(addressB)
        );
        assertEq(amount, 200);
        assertEq(timestamp, block.timestamp);
    }

    function testBidFailContractDeprecated() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        vm.prank(addressB);
        mockCurrency.approve(address(marketPlace), 200);
        registry.setContractStatus(address(marketPlace), false);
        vm.prank(addressB);
        vm.expectRevert(bytes4(keccak256("ContractIsDeprecated()")));
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 0,
            externalFunds: 200
        });
    }

    function testBidFailAuctionNotActive() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 100,
            currency: address(mockCurrency)
        });
        marketPlace.cancelAuction(1);
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        vm.startPrank(addressB);
        mockCurrency.approve(address(marketPlace), 200);
        vm.expectRevert(bytes4(keccak256("AuctionIsNotActive()")));
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 0,
            externalFunds: 200
        });
    }

    function testBidFailBidEnough() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 200,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        vm.startPrank(addressB);
        mockCurrency.approve(address(marketPlace), 550);
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 0,
            externalFunds: 300
        });
        vm.stopPrank();

        vm.expectRevert(bytes4(keccak256("BidIsNotHighEnough()")));
        vm.prank(addressA);
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 0,
            externalFunds: 250
        });
    }

    function testBidFailBidTooLow() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 300,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        vm.startPrank(addressB);
        mockCurrency.approve(address(marketPlace), 200);
        vm.expectRevert(bytes4(keccak256("BidLoweThanReservePrice()")));
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 0,
            externalFunds: 200
        });
    }

    function testBidFailNotEnoughBalance() public {
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 300,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        vm.startPrank(addressB);
        mockCurrency.approve(address(marketPlace), 200);
        vm.expectRevert(bytes4(keccak256("NotEnoughBalance()")));
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 100,
            externalFunds: 400
        });
    }

    function testResolveAuction() public {
        // create an auction
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        // create a bid
        vm.startPrank(addressB);
        mockCurrency.approve(address(marketPlace), 200);
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 0,
            externalFunds: 200
        });
        assertEq(marketPlace.escrow(address(mockCurrency)), 200);

        // do accounting correctly when the winner or auctioner claims
        skip(5 days);
        marketPlace.resolveAuction(1);
        // escrow releases funds
        assertEq(marketPlace.escrow(address(mockCurrency)), 0);
        // add fee to the system balance
        (address systemWallet, uint256 fee) = registry.feeInfo(200);
        assertEq(
            marketPlace.claimableFunds(systemWallet, address(mockCurrency)),
            fee
        );
        // add seller gains to the seller balance
        assertEq(
            marketPlace.claimableFunds(addressA, address(mockCurrency)),
            200 - fee
        );

        // transfer nft from the platform to the recipient correctly
        assertEq(nft721.balanceOf(address(marketPlace)), 0);
        assertEq(nft721.ownerOf(1), address(addressB));
        assertEq(nft721.balanceOf(address(addressB)), 1);
    }

    function testResolveAuctionFailAuctionIsnotCancelledOrEnded() public {
        // create an auction
        nft721.safeMint(addressA, 1);
        vm.startPrank(addressA);
        nft721.approve(address(marketPlace), 1);
        marketPlace.createAuction({
            isERC721: true,
            nftAddress: address(nft721),
            nftId: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days,
            reservePrice: 100,
            currency: address(mockCurrency)
        });
        mockCurrency.transfer(addressB, 10_000);
        vm.stopPrank();

        // create a bid
        vm.startPrank(addressB);
        mockCurrency.approve(address(marketPlace), 200);
        marketPlace.bid({
            auctionId: 1,
            amountFromBalance: 0,
            externalFunds: 200
        });

        vm.expectRevert(bytes4(keccak256("AuctionIsNotEndOrCancelled()")));
        marketPlace.resolveAuction(1);
    }
}