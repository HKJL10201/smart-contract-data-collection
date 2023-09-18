pragma solidity ^0.4.21;

contract LotteryContract {
    uint256 systemBeginTime;
    address eip20ContractAddress;
    struct Ticket {
        address owner;
        bytes32 hash;
        uint32 revealIndex;
        bool revealed;
        bool redeemed;
    }

    struct Lottery {
        Ticket[] tickets;
        uint32 currentRandom;
        uint32 lastRevealIndex;
    }

    Lottery[] lotteries;


    modifier purchaseStageOnly() {
        require(
            ((now - systemBeginTime) / (1 weeks)) % 2 == 0,
            "Current lottery is in reveal stage, you can't purchase tickets this week."
        );
        _;
    }
    modifier revealStageOnly() {
        require(
            ((now - systemBeginTime) / (1 weeks)) % 2 == 1,
            "Current lottery is in submission stage, you can't reveal numbers this week."
        );
        _;
    }
    modifier currentLotteryOnly(uint32 lotteryNumber) {
        require(
            lotteryNumber == (now - systemBeginTime) / (2 weeks),
            "You can make the current action only in the current lottery."
        );
        _;
    }
    modifier pastLotteryOnly(uint32 lotteryNumber) {
        require(
            lotteryNumber < (now - systemBeginTime) / (2 weeks),
            "You can make the current action only in the past lotteries."
        );
        _;
    }
    modifier existingLotteryOnly(uint32 lotteryNumber) {
        require(
            lotteryNumber < lotteries.length,
            "Lottery doesn't exists, or skipped due to no submission."
        );
        _;
    }
    modifier ticketExists(uint32 lotteryNumber, uint32 ticketNumber) {
        require(
            (lotteries[lotteryNumber].tickets.length > ticketNumber),
            "Ticket doesn't exists"
        );
        _;
    }
    modifier ticketOwnerOnly(uint32 lotteryNumber, uint32 ticketNumber) {
        require(
            (lotteries[lotteryNumber].tickets[ticketNumber].owner == msg.sender),
            "Ticket doesn't belong to you"
        );
        _;
    }
    modifier notRevealedTicketOnly(uint32 lotteryNumber, uint32 ticketNumber) {
        require(
            (lotteries[lotteryNumber].tickets[ticketNumber].revealed == false),
            "The number submitted in this ticket is already revealed before"
        );
        _;
    }
    // modifier revealedTicketOnly(uint32 lotteryNumber, uint32 ticketNumber) {
    //    require(
    //        (lotteries[lotteryNumber].tickets[ticketNumber].revealed == true),
    //        "The number submitted in this ticket was not revealed before"
    //    );
    //    _;
    // }
    //    modifier notRedeemedTicketOnly(uint32 lotteryNumber, uint32 ticketNumber) {
    //        require(
    //            (lotteries[lotteryNumber].tickets[ticketNumber].redeemed == false),
    //            "The number submitted in this ticket is already revealed before"
    //        );
    //        _;
    //    }

    function LotteryContract(
        address _eip20ContractAddress
    ) public {
        eip20ContractAddress = _eip20ContractAddress;
        systemBeginTime = now;
    }

    // Purchases a ticket with a secret number submitted to reveal in next stage.
    function purchaseTicket(uint32 number)
    purchaseStageOnly
    public returns (uint32 lotteryNumber, uint32 ticketNumber){
        lotteryNumber = uint32((now - systemBeginTime) / (2 weeks));
        // create the lottery upon first submission (thus, be careful to check if a lottery exists in reveal & redeem)
        if (lotteries.length <= lotteryNumber) {
            lotteries.length = lotteryNumber + 1;
        }
        // assume no more than 2^31-2 tickets submitted per lottery.
        // (That's critically important due to random number mechanism explained below in redeem section)
        require(
            lotteries[lotteryNumber].tickets.length < 2**31-2,
            "Maximum number of tickets are already purchased for that lottery"
        );
        require(
            eip20ContractAddress.call(abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender, this, 10
            )),
            "Please make sure to approve 10 TL tokens for this contract in EIP20 TL Token contract"
        );

        ticketNumber =  uint32(lotteries[lotteryNumber].tickets.length);
        lotteries[lotteryNumber].tickets.push(Ticket({
            owner: msg.sender,
            hash: keccak256(abi.encodePacked(number, lotteryNumber, ticketNumber, msg.sender)),
            revealIndex: 0,
            revealed: false,
            redeemed: false
        }));
    }

    // Reveals submitted number in a ticket in the current lottery
    // lotteryNumber is only requested to make sure
    // the sender knows which lottery he/she is revealing his number
    // (it is only taken to better inform the sender on error)
    // ie: let's say that sender purchased a ticket in lottery 1 (week 3)
    // then, forgot to reveal that number in week 4.
    // then, tried to reveal that number in week5 (reveal period of lottery 2)
    // if the function did not take a lotteryNumber it would only tell the sender
    // that either the ticket doesn't exist in the current lottery, it doesn't belong to him/her
    // or would try to reveal the number if he submitted a ticker in lotter 2 also
    // and for some reason it had the same ticketNumber. In such case,
    // the sender my accidentally reveal another ticket of hers/his if he/she submitted the same number
    // or would receive error, the sent number is wrong which would be very confusing for him/her.
    // now, instead we take lotteryNumber and better inform the sender in such situation
    // with saying that he/she can't reveal number because that lottery has already finished.
    function revealNumber(uint32 number, uint32 lotteryNumber, uint32 ticketNumber)
    currentLotteryOnly(lotteryNumber) revealStageOnly
    ticketExists(lotteryNumber, ticketNumber)
    ticketOwnerOnly(lotteryNumber, ticketNumber)
    notRevealedTicketOnly(lotteryNumber, ticketNumber)
    public {
        require(
            (lotteries[lotteryNumber].tickets[ticketNumber].hash == keccak256(abi.encodePacked(number, lotteryNumber, ticketNumber, msg.sender))),
            "You revealed a wrong number, make sure to reveal the number you submitted"
        );
        lotteries[lotteryNumber].tickets[ticketNumber].revealed = true;
        lotteries[lotteryNumber].tickets[ticketNumber].revealIndex = lotteries[lotteryNumber].lastRevealIndex;
        lotteries[lotteryNumber].lastRevealIndex += 1;
        lotteries[lotteryNumber].currentRandom ^= number;
    }

    function queryTicket(uint32 lotteryNumber, uint32 ticketNumber)
    pastLotteryOnly(lotteryNumber)
    existingLotteryOnly(lotteryNumber)
    ticketExists(lotteryNumber, ticketNumber)
    ticketOwnerOnly(lotteryNumber, ticketNumber)
    public view returns (uint64 wonAmount) {
        // using some modifiers inline due to stack too deep error !!!
        require(
            (lotteries[lotteryNumber].tickets[ticketNumber].revealed == true),
            "The number submitted in this ticket was not revealed before"
        );
        uint32 ticketIndex = lotteries[lotteryNumber].tickets[ticketNumber].revealIndex;
        uint64 totalMoney = uint32(lotteries[lotteryNumber].tickets.length);
        totalMoney *= 10;
        uint32 validTicketCount = lotteries[lotteryNumber].lastRevealIndex;
        uint64 seed = ((lotteries[lotteryNumber].currentRandom) % (2**31-2)) + 1;
        // we need a seed in range [1, 2^31-1] for our PRNG
        // however our initial random number is in range [0, 2^32 - 1]
        // if we simply find the seed with ((currentRandom) % (2^31-2)) + 1;
        // that means the probability of seeds 1 and 2 are 1 times higher than other seeds resulting in an unfair advantage
        // and these chances are precisely (1/(2^30-1)) more.
        // ie: each seed has a (2/(2^31-2)) chance of being picked, but seeds 1 and 2 has a (3/(2^31-2)) chance of being picked.
        // since our PRNG allows each seed to be in range [1, 2^32-2] which as 2^32-2 entries, we limit validTicketCount to that number
        // if required validTicketCount can be increased by using two seeds per prize in a [seed1][seed2] % validTicketCount manner
        // but no such requirement was given, so it is assumed that no more than 2^32-2 tickets per lottery is accepted.
        // to prevent such situation we add the below statement if (currentRandom == 2^32-2 || currentRandom == 2^32-1) customSeed = (2^31-1) - validTicketCount
        if (lotteries[lotteryNumber].currentRandom == 2**32-2 || lotteries[lotteryNumber].currentRandom == 2**32-1) {
            seed = (2**31-1) - validTicketCount;
            // there's still a tiny bit of unfairness here: since the cases of validTicketCount being 0 or 1 is meaningless
            // (ie: either there's no tickets or there's only one and thus the winner is already known)
            // if validTicketCount = 0, we know that redeem function can't be called thus no need to make sure the formula works in such case
            // however the formula should also work when validTicketCount = 1 but its result doesn't really matter.
            // thus, validTicketCount can be thought of as being in range [2, 2^31-2]
            // thus, (2^31-1)-validTicketCount is in range [1, 2^31-3] and 2^31-2 seed is not reachable
            // to share that unreachableness we add the below statement if (customSeed == 2^31-3)customSeed += currentRandom - 2^32-2
            if (seed == 2**31-3) {
                seed += lotteries[lotteryNumber].currentRandom - 2**32-2;
            }
            // so that both 2^31-3 and 2^31-2 seeds are equally reachable but less likely than other seeds
        }
        // overall that causes all seeds to have
        // (2/(2^31-2) + 2/(2^31-2) * (1/2^31-3)) = (2^32-4)/((2^31-2)(2^31-3)) = (2^32-4)/(2^62-5*2^31+6) = 9.313225759e-10 chance
        // seeds 2^31-3 and 2^31-2 have
        // (2/(2^31-2) + 1/(2^31-2) * (1/2^31-3)) = (2^32-5)/((2^31-2)(2^31-3)) = (2^32-5)/(2^62-5*2^31+6) = 9.313225757e-10 chance
        // so their chance differ by 2e^-19 whereas each has at least 9e-10 chance
        // so those two seeds are less possible in an ignoribly small amount, which gives an extremely small unfair DISADVANTAGE to these seeds.
        // HOWEVER an unfair disadvantage to one/two seeds are far less important than an unfair advantage to one/two seeds.

        // still to make sure that tiny little bit of unfairness can't be traced and calculated beforehand and not localized to anywhere
        // instead of giving the initial prize to the first seed, we make one random iteration and give the initial prize to the next seed.
        wonAmount = 0;
        while (totalMoney > 0) {
            seed = (seed * 16807) % 2147483647; // Park and Miller in the Oct 88 issue of CACM
            if ((seed - 1) % validTicketCount == ticketIndex) { // seed >= 1
                // ticket won the next prize
                wonAmount += (totalMoney / 2) + (totalMoney % 2);
            }
            totalMoney = totalMoney / 2;
        }
    }

    // Redeem ticket prizes from a finished lottery
    function redeemTicket(uint32 lotteryNumber, uint32 ticketNumber)
    pastLotteryOnly(lotteryNumber)
    existingLotteryOnly(lotteryNumber)
    ticketExists(lotteryNumber, ticketNumber)
    ticketOwnerOnly(lotteryNumber, ticketNumber)
    // revealedTicketOnly(lotteryNumber, ticketNumber)
    // notRedeemedTicketOnly(lotteryNumber, ticketNumber)
    public returns (uint64 wonAmount) {
        // using some modifiers inline due to stack too deep error !!!
        require(
            (lotteries[lotteryNumber].tickets[ticketNumber].revealed == true),
            "The number submitted in this ticket was not revealed before"
        );
        require(
            (lotteries[lotteryNumber].tickets[ticketNumber].redeemed == false),
            "The requested ticket is already redeemed before"
        );
        wonAmount = queryTicket(lotteryNumber, ticketNumber);
        // below require should always succeed, if it doesn't that means
        // lottery contract does not have enough TL tokens in the EIP20 contract
        // which means that something went terribly wrong with this lottery contract
        // it is put there just in case to prevent setting redeemed=true
        // if the TL tokens weren't successfully transferred for some reason
        require(
            eip20ContractAddress.call(abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender, wonAmount
            )),
            "Failed to transfer tokens to your account on EIP20 TL Token contract, please try again later"
        );
        lotteries[lotteryNumber].tickets[ticketNumber].redeemed = true;
    }
}
