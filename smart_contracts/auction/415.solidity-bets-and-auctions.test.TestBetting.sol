// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestFramework.sol";

contract TestBetting {
    // Adjust this to change the test code's initial balance
    uint public initialBalance = 100000000 wei;

    uint256 constant public marketInitialBalance = 10000 wei;
    uint256 constant public betterInitialBalance = 1000 wei;

    event BetEvent(uint number);
    event BetterFirst(uint number);
    event BetterSecond(uint number);

    BoxOracle oracle;
    BettingMaker bettingMaker;
    Betting betting;
    Better better1;
    Better better2;
    Better better3;
    Better better4;
    Better better5;

    //can receive money
    receive() external payable {}

    fallback() external payable {}

    constructor() {}

    function beforeEach() public {
        oracle = new BoxOracle();
        bettingMaker = new BettingMaker();
        betting = new Betting(address(bettingMaker), "Hrgovic", "Babic", 2 wei, 100 wei, 100 wei, oracle);
        bettingMaker.setBetting(betting);
        payable(bettingMaker).transfer(marketInitialBalance);

        better1 = createBetter(betting);
        better2 = createBetter(betting);
        better3 = createBetter(betting);
        better4 = createBetter(betting);
        better5 = createBetter(betting);
    }

    function createBetter(Betting _betting) internal returns (Better) {
        Better better = new Better(_betting);
        payable(better).transfer(betterInitialBalance);
        return better;
    }

    function testMakingBet() public {// test making a basic bet
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(20 wei, 1), "Better must be able to bet");
        require(better2.makeBet(30 wei, 2), "Better must be able to bet");
        Assert.isTrue(address(betting).balance == marketInitialBalance + 50 wei, "Contract balance should be bigger when bet is placed.");
    }

    function testMakingBetRequirements() public {// test different requirements for making a bet
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(20 wei, 1), "Better must be able to bet");
        Assert.isFalse(better1.makeBet(1 wei, 1), "There exists a minimum amount for placing bet.");
        Assert.isFalse(better1.makeBet(101 wei, 1), "There exists a maximum amount for placing bet.");
        Assert.isFalse(better1.makeBet(2 wei, 3), "Player ID should be 1 or 2.");
        Assert.isFalse(bettingMaker.makeBet(2 wei, 1), "Bet market maker should not be able to make bets.");
        oracle.setWinner(1);
        Assert.isFalse(better1.makeBet(10 wei, 1), "Bet should not be placed after match is finished.");
    }

    function testClaimingBets() public {// test claiming while threshold is not crossed.
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(30 wei, 1), "Better must be able to bet");
        require(better2.makeBet(50 wei, 1), "Better must be able to bet");
        require(better3.makeBet(10 wei, 2), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isTrue(better1.claimWinningBets(), "Better 1 must be able to claim his rewards.");
        Assert.isTrue(better2.claimWinningBets(), "Better 2 must be able to claim his rewards.");
        Assert.isTrue(better3.claimWinningBets(), "Better 3 must be able to claim his rewards.");
        Assert.isTrue(address(better1).balance == betterInitialBalance + 30 wei, "The bet should be doubled while threshold is not crossed.");
        Assert.isTrue(address(better2).balance == betterInitialBalance + 50 wei, "The bet should be doubled while threshold is not crossed.");
        Assert.isTrue(address(better3).balance == betterInitialBalance - 10 wei, "The bet should be lost if outcome is different.");
    }

    function testClaimingMultipleBetsFromSameBetter() public {// test claiming multiple different bets from the same better
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(30 wei, 1), "Better must be able to bet");
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isTrue(better1.claimWinningBets(), "Better must be able to claim his rewards.");
        Assert.isTrue(address(better1).balance == betterInitialBalance + 80 wei, "Each better should be able to place multiple different bets.");
    }

    function testClaimingBetsWhenThresholdCrossed() public {// test claiming rewards when coefficients are changed
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        require(better2.makeBet(70 wei, 2), "Better must be able to bet");
        require(better3.makeBet(10 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isTrue(better1.claimWinningBets(), "Better must be able to claim his rewards.");
        Assert.isTrue(better3.claimWinningBets(), "Better must be able to claim his rewards.");
        Assert.isTrue(address(better1).balance == betterInitialBalance + 50 wei, "The bet should return according to her initial coefficient value, even though current coefficient is different.");
        Assert.isTrue(address(better3).balance == betterInitialBalance + 14 wei, "If the bet is placed after threshold value, coefficient should change.");
    }

    function testClaimingMultipleBetsFromSameBetterDifferentCoef() public {// test claiming rewards for the same better but multiple different bets with different coefs
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        require(better2.makeBet(70 wei, 2), "Better must be able to bet");
        require(better1.makeBet(10 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isTrue(better1.claimWinningBets(), "Better must be able to claim his rewards.");
        Assert.isTrue(address(better1).balance == betterInitialBalance + 64 wei, "Same better should be able to place multiple different bets with different coefficients.");
    }

    function testClaimingMultipleBetsFinal() public {// another test for claiming rewards for different betters
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        require(better2.makeBet(60 wei, 2), "Better must be able to bet");
        require(better3.makeBet(40 wei, 1), "Better must be able to bet");
        require(better4.makeBet(30 wei, 1), "Better must be able to bet");
        oracle.setWinner(2);
        Assert.isTrue(better1.claimWinningBets(), "Better must be able to claim his rewards only if he won.");
        Assert.isTrue(better2.claimWinningBets(), "Better must be able to claim his rewards.");
        emit BetEvent(address(better2).balance);
        Assert.isTrue(address(better1).balance == betterInitialBalance - 50 wei, "Bet should be lost if outcome is different.");
        Assert.isTrue(address(better2).balance == betterInitialBalance + 60 wei, "Bet should be won if outcome is the same as in the bet.");
    }

    function testClaimingBeforeEnding() public {// test claiming rewards before the end of the match
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(30 wei, 1), "Better must be able to bet");
        Assert.isFalse(better1.claimWinningBets(), "Better must not be able to claim his rewards before game ends.");
    }

    function testClaimingSuspendedBet() public {// test claiming rewards if the match is suspended
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        require(better2.makeBet(60 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isFalse(better1.claimWinningBets(), "Better should not be able to claim winning bets if betting on match is suspended.");
    }

    function testMakingBetSuspendedMatch() public {// test making a bet if the match is suspended
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(90 wei, 1), "Better must be able to bet");
        require(better2.makeBet(20 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isFalse(better1.makeBet(10 wei, 1), "Better should not be able to place bet if match is suspended.");

    }

    function testRefundingNotSuspended() public {// test claiming suspended bets if the match is not suspended
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(90 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isFalse(better1.claimSuspendedBets(), "Bet must be suspended to claim funded bets.");
    }

    function testRefundSuspended() public {// test claiming suspended bets
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        require(better2.makeBet(60 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isTrue(better1.claimSuspendedBets(), "Better should be able to claim suspended bets if betting on match is suspended.");
        Assert.isTrue(better2.claimSuspendedBets(), "Better should be able to claim suspended bets if betting on match is suspended.");
        Assert.isTrue(address(better1).balance == betterInitialBalance, "Better should be able to claim suspended bets if betting on match is suspended.");
        Assert.isTrue(address(better2).balance == betterInitialBalance, "Better should be able to claim suspended bets if betting on match is suspended.");
    }

    function testClaimingLosingBets() public {// test claiming losing bets by bet market maker
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        require(better2.makeBet(40 wei, 1), "Better must be able to bet");
        oracle.setWinner(2);
        Assert.isTrue(better1.claimWinningBets(), "Better should be able to claim winning bets if he won.");
        Assert.isTrue(bettingMaker.claimLosingBets(), "Better should be able to claim losing bets if everybody else collected it.");
        Assert.isTrue(address(bettingMaker).balance == marketInitialBalance + 90 wei, "Bet market maker should be able to claim losing bets");
    }

    function testClaimingLosingBetsBeforeEverybodyClaimed() public {
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        require(better2.makeBet(40 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isTrue(better1.claimWinningBets(), "Better should be able to claim winning bets if he won.");
        Assert.isFalse(bettingMaker.claimLosingBets(), "Better should be able to claim losing bets ONLY if everybody else collected it.");
    }

    function testClaimingLosingBetsByBetter() public {
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        oracle.setWinner(1);
        Assert.isTrue(better1.claimWinningBets(), "Better should be able to claim winning bets if he won.");
        Assert.isFalse(better1.claimLosingBets(), "ONLY bet market maker can claim losing bets.");
    }

    function testClaimingLosingBetsAfterSuspendedOrNotFinished() public {
        payable(betting).transfer(marketInitialBalance);
        require(better1.makeBet(50 wei, 1), "Better must be able to bet");
        Assert.isFalse(better1.claimLosingBets(), "Bet market maker can claim losing bets only after match has finished.");
        require(better1.makeBet(60 wei, 1), "Better must be able to bet");
        oracle.setWinner(2);
        Assert.isFalse(better1.claimLosingBets(), "Bet market maker can claim losing bets only if the match was not suspended.");
    }

}