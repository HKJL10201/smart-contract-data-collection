// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol"; //taken from "https://docs.chain.link/docs/get-the-latest-price/"
import "@openzeppelin/contracts/access/Ownable.sol"; // taken from "https://docs.openzeppelin.com/contracts/4.x/api/access#ownable"
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol"; // taken from "https://docs.chain.link/docs/get-a-random-number/"

contract Lottery is VRFConsumerBase, Ownable {
    // here we're inheriting "VRFConsumerBase", "Ownable" into our "Lottery" contract
    // here we're going to need to keep the track of all the different players(i.e everybody who signsup for this lottery)...
    // ...So for this we need to make address payable
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness; // for keeping track of the most recent random number
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed; // used pulling code from "https://docs.chain.link/docs/get-the-latest-price/"
    // for making sure that, we're not ending the lottery before the lottery even starts or we're not enteriing a lottery when a lottery hesn't even begun...
    // ...So we're going to want a way to iterate through the differet phases of this lottery and for that we can do "enum"...
    // ...we can read more about "enum" in the solidity documentation here:-"https://docs.soliditylang.org/en/v0.8.10/types.html")
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    // Now creating a variable type "LOTTERY_STATE"
    LOTTERY_STATE public lottery_state;
    uint256 public fee; // It is associated to LINK token needed to pay for the request. It changes from blockchain to blockchain so we will use it as an input parametrs as well in our "constructor()"
    bytes32 public keyhash; // It is a way to uniquely identify the Chainlink_VRF Node
    event RequestedRandomness(bytes32 requestId);

    // So, now we've identified a new type of event called "RequestedRandomness()" it's really similar to the "enum" in this regard.
    // So to emit one of these events all we have to do in our "endLottery()" bid is we'll do "emit RequestedRandomness(requestId);" which we can see below

    // OPEN is stage"0"
    // CLOSED is stage"1"
    // CALCULATING_WINNER is stage"2"

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link, // as we want to pass the address of our price feed as a contructor parameter and some more parameters for making it similar to "VRFConsumerBase()" parameters, finally using inherited constructor from "VRFConsumerBase()" to use it's parameter also
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        //
        usdEntryFee = 50 * (10**18); // in terms of wei
        // as we know we need a conversion rate, so we're going to want to use a chain link price feed from "https://docs.chain.link/docs/get-the-latest-price/" and we can simply copy paste the code but for the sake of robustness,
        // we need to actually set this up, so we're going to need to pull from the "priceFeedAddress" to convert $50 from USD to ETH (and for this we had to first save this in the "contract Lottery{}" and then use it in below "AggregatorV3Interface(_priceFeedAddress)" code...
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress); // used to convert eth to usd
        // Right when we initialize our contract here we're going to want to set our "LOTTERY_STATE" to be closed
        lottery_state = LOTTERY_STATE.CLOSED; // this is much more readable but
        // we can also write the above line as "lottery_state = 1" as "1" stands for closed
        fee = _fee; // It is associated to LINK token needed to pay for the request.
        keyhash = _keyhash; // It is a way to uniquely identify the Chainlink_VRF Node
    }

    // below is the function for entry of the user and since we want them to pay in ethereum so we're going to need to make this "entry()" payable.
    function enter() public payable {
        // $50 minimum and also we have to store this value somewhere(i.e we want to store this value right when our contract is deployed) so we save this in our contructor
        // below code shows that, we can only enter if somebody started this lottery.
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!"); // checking whether it's greater than the minimum value
        players.push(msg.sender); // Anytime sombody enters this code help us know that.
    }

    // below is the function for entrance fee amount
    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData(); // this code is taken from "solidity code" of "https://docs.chain.link/docs/get-the-latest-price/" by removing rest of the parameters from "funtion getThePrice()...{...}"
        // now we have to convert the "int256 price" to "uint256 price" so...
        uint256 adjustedPrice = uint256(price) * 10**10; // converting into 18 decimal places
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice; // for cancelling out additional decimals
        return costToEnter;
        // ImportantNote:- here in this function we are using lots of math so, it's recommended to use SafeMath functions but here we are skipping it for now and use our raw code
        // because in newer versions of "Solidity" it's already given...as sending this exact code to production would be a bad_idea for at least the reason of the SafeMath functions. Now, lets just test our "getEntranceFee()"
    }

    // below is the function for starting the lottery bid and it's need to be called only by our lottery Owner/Admin
    // we could write our "onlyOwner" modifier or we can use OpenZeppelin's access control or OpenZepplin's ownable function but we're going to use "Ownable" instead...
    // using this link:-"https://docs.openzeppelin.com/contracts/4.x/api/access#ownable" copy the "import "@openzepplin/..." and paste it above
    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    // Below is the 1st Transaction where we're going to request the data from the "Chainlink Oracle":-

    // below is the function for ending the lottery bid and it's also need to be called only by our lottery Owner/Admin.
    // Now lets talk about "Randomness":-
    // As we know that blockchain is a deterministic system and this is super advantageous because this allows us to create smart contracts that can reach consensus very easily but random number is much harder...
    // ...If let's say you had a blockchain with a whole bunch of different nodes and each node responds and gives their own random value then each node is never going to be able to sync up or agree on a random number,...
    // ...but what we could do is we could base the random number on some other attributes in the system, but then it's not really random it's actually going to be pseudorandom.
    // So getting truly random in a deterministic system is actually impossible and we know in Computer Science we actually know that even when you call "math.random()" in our javascript, what our computer is really doing it's looking at some place in memory grabbing some value and saying,
    // "Hey, this is probably random enough here go ahead and use this now in smart contracts", especially when working with any type of financial applictaion such as lottery having an exploitable randomness function means that our lottery is at risk of being hacked or destroyed,
    // as it's not really random!, So we will be going to see this "Insecure way/method" first and then the "Secure way/method", because it's a quick and dirty way to get a pseudo random number but plesase! don't try this "Insecure Way" in any production use cases...
    // ...and then we talk why it's so vulnerable and not a good method of randomness and what some insecure protocols will do is they'll use a globally available variable and hash it so in our smart contracts there's actually a number of globally available variables,...
    // ...one of those as we saw above is "msg.value"  and "msg.sender" and we can see the whole list of globally available  variables list in solidity documentation at:- "https://docs.soliditylang.org/en/v0.8.7/units-and-global-variables.html", Let's see "block.difficulty (uint): current block difficulty".
    function endLottery() public onlyOwner {
        // Remember, as we said that `the time between different block generation is called the "block time"(view this at:-"https://2miners.com/eth-network-difficulty")` and we can keep that blocktime as ease by changing the block difficulty over time(i.e `The harder the problem/the proof of work algorithm the longer it's going to take or the more nodes we're going to need to solve that problem`)...
        // ...there's this constantly recalculating metric called "Ethereum Difficulty/Block Difficulty" depending on the chain that we're working on that constantly changes, so we might think this would be a great use of randomness right because it's a somewhat hard to predict number so what alot of people do is they think that,...
        // ... Hey! those sound pretty random let's use them as a unit of randomness and what we'll see is something like...in below code and we are converting everything here to "uint256(...)", the reason we're doing this of course is because we're going to want to pick a random winner based off of an index right from our "players array or list" (i.e. "address payable[] public players;") in above code
        // uint256(
        //    keccack256(
        //        abi.encodePacked( // "abi...." here is keyword for some low-level work
        //            nonce, // nonce is preditable (aka, transaction number)
        //            msg.sender, // msg.sender is predictable
        //            block.difficulty, // can actually be manipulated by the miners!
        //            block.timestamp // timestamp is predictable
        //        )
        //    )
        // ) % players.length;
        // basically in above code we are basically trying to take a bunch of seemingly random numbers and mash them all together in a hashing...
        // ...function and saying that this is pretty random but the issue here is that the hashing function itself isn't random but it's exactly the same "keccak256()",...
        // ... and hence it's always going to hash everything exactly the same way so we're not actually making it more random by
        // hashing it all these numbers inside are the pieces that actually determine how random it is...So, if the "block.difficulty" is random then this will be a random method...
        // ...but if the "block.difficulty" isn't random this won't be a random method and can be manipulated by the miners see above code comments...
        // ...this all provide chance to easily win the lottery for the miners. And now lets see the best practices..
        // So, in order to get true Random number we have to look outside the blockchain as we said earlier blockchain itself is a deterministic system so we need a "number"...
        // ...outside the blockchain but what we can't do is we can't use just an "api" that gives a random number because "api" might become corrupted if they're malicious or if they go down if something happens etc.
        // So what we need is a provable way to get a random number where "Chainlink_VRF(i.e. Chainlink Verifiably Randomized Function)" comes handy as it's a way to get a provably random number into our smart contract and...
        // ...it has an on-chain contract that checks the response of a Chainlink node to make sure the number is truly random using some "cryptographic method"...
        // ...It's able to check a number of the parameter that the "Chainlink_VRF" started and ended with to make sure that it's truly random.
        // It's alraedy used for protocols like Aaeagotchi, Ether Cards, PoolTogether and others because it is a secure reliable and incredibly powerful to generate random number in a decentralized system.
        // So now lets visit the Chainlink Documentation:-https://docs.chain.link/docs/get-a-random-number/ and click "deploy this contract using `Remix_IDE`"...
        // ...(we reache to https://remix.ethereum.org/#url=https://docs.chain.link/samples/VRF/RandomNumberConsumer.sol&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.7+commit.e28d00a7.js) and watch it,...
        // ...we will get to know that the code is using "Kovan network" but we can change the network from "VRF Contracts page"(i.e. "https://docs.chain.link/docs/vrf-contracts/") and grab the "Rinkeby Network addresses" or other network to use...
        // We will see that we are importing code from Chainlink Package and our contract is inheriting  the abilities of "VRFConsumerBase.sol" contract.
        // lets see its code at "https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.6/VRFConsumerBase.sol" and we found that it has a
        // "constructor(address _vrfCoordinator, address _link) public {
        // vrfCoordinator = _vrfCoordinator;
        // LINK = LinkTokenInterface(_link);
        // }" so here our 'contructor()' has two `address` one for "_vrfCoordinator" which is a contract that's been deployed `on-chain` that actually checks/verify to make sure our numbers are random and other `address` for "_link" token(i.e Chainlink token...here 'ERC20') which we're going to use as a payment to the chainlink node for its services.
        // Also in our original code for 'RandomNumberConsumer.sol'(i.e https://remix.ethereum.org/#url=https://docs.chain.link/samples/VRF/RandomNumberConsumer.sol&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.7+commit.e28d00a7.js)...
        // ...has "contructor()" this means double `contructor()` where we has "keyhash"(It uniquely identifies the Chainlink node that we're going to use) and...
        // ... "fee"(It is the amount which we're going to pay to the chainlink node for delivering us this random number) inside the 'constructor()'
        // Let's talk about this Important things here:-
        // In `ETH` whenever we make transaction we have to pay some `ETH gas/ Transaction gas` this is to pay the smart contract platform a little bit of ETH for performing our transaction...
        // ... with a samrt contract that operates with an oracle so here we have to pay some `Link gas/Oracle gas` to the 'Oracles' a fee for their services for providing data or some type of external computation for a smart contract
        // i.e ETH -> Pay some ETH gas or Transaction gas
        // and LINK-> Pay some LINK gas or Oracle gas
        // Then we arise a question that, "Why didn't we pay 'Oracle gas' when working with the Chainlink "getLatestPrice()" as `price_feed` thing...
        // ...(we can see this function here:-"https://docs.chain.link/docs/get-the-latest-price/") because for `price_feeds` somebody has actually already paid 'Oracle gas' for the data to be returned for us.
        // We can watch all the sponsors at the end here:-"https://data.chain.link/ethereum/mainnet/crypto-usd/eth-usd" that are paying the `Oracle Gas` to bring this data on chain for us.
        // Since, no other protocol is getting a random number for us, hence, we've to pay the 'Oracle gas' here.
        // Now in this "RandomNumberConsumer.sol"contract(i.e https://remix.ethereum.org/#url=https://docs.chain.link/samples/VRF/RandomNumberConsumer.sol&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.7+commit.e28d00a7.js) we have a function for "requesting randomness" i.e....
        /*function getRandomNumber() public returns (bytes32 requestId) {
          require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
          return requestRandomness(keyHash, fee);
          }*/
        // So, here the above function calls "requestRandomness()" which is inherited from the `VRFConsumerBase.sol`...which is as follows taken from "https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.6/VRFConsumerBase.sol"

        /*function requestRandomness(bytes32 _keyHash, uint256 _fee)
            internal returns (bytes32 requestId)
          {
            LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
            // This is the seed passed to VRFCoordinator. The oracle will mix this with
            // the hash of the block containing this request to obtain the seed/input
            // which is finally passed to the VRF cryptographic machinery.
            uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
            // nonces[_keyHash] must stay in sync with
            // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
            // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
            // This provides protection against the user repeating their input seed,
            // which would result in a predictable/duplicate output, if multiple such
            // requests appeared in the same block.
            nonces[_keyHash] = nonces[_keyHash].add(1);
            return makeRequestId(_keyHash, vRFSeed);
           } 
        */

        // the above requestRandomness() function sends our Oracle gas fee or the Link Token and...
        // ...it's going to call this "transferAndCall()" specific to the particular "LINK".
        // If we want to know how much Oracle gas we're going to pay, just have a look to this:- "https://docs.chain.link/docs/vrf-contracts/"
        // ...and we will get to know where the most recently deployed VRF's are...and how much the fee is...etc.
        // Now, getting a random number actually follows "Request & Receive" style of working with Data.
        // Let's go ahead and just try this out and see what this means practically in RemixIDE for "RandomNumberCoonsumer.sol" contract here:-
        // "https://remix.ethereum.org/#url=https://docs.chain.link/samples/VRF/RandomNumberConsumer.sol&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.7+commit.e28d00a7.js"
        // ...we will be using environment "Injected Web3" with Kovan Test network's "Test ETH" and "Test LINK"(for finding the most up-to-date faucets look here:- "https://docs.chain.link/docs/link-token-contracts/")
        // Grab the "Testnet account address" from your Metamask and put into the Kovan Faucet link which we get from above website and request for "10 test Link" and "0.1 test ETH"
        // and after connecting "kovan.etherscn.io" to our metamask we will able to view the Transaction by clicking on the "Transaction hash" that we get in the end
        // We can see that Tokens Transferred from "One Address to our Address for 10 ChianlinkToken" and by clicking on the "10 ETH ChainlinkToken" link we get a new webpage with "Contract Address" copy the address from "Profile Summary Block"
        // and add the "LINKs" to Metamask's Asset section. So now we have "0.1 ETH" and "20 LINK" or "10 LINK". Now, lets deploy our "RandomNumberConsumer.sol" contract on "Kovan Test Network" at "RemixIDE"
        // Now check the "randomResult" button by clicking...it will be zero because we haven't got a random number. So, we are going to do somoething intentionally wrong because there's a good chance that we'll run into this at some point...
        // ...i.e if we hit "getRandomNumber" button right now we will get this error "Gas estimation failed" but we have plenty of "ETH"...Why would this fail...? the reason that it's failing because the contract doesn't have any "Oracle gas"...
        // ...so we need to fund this "Deployed Contract address" with some link to actually get a random number so we're going to hit copy the "Deployed Contract address" and paste in "Send" metamask option and send 1 LINK from our 10 LINK...
        // ...this is probably overkill because as we saw in "RandomNumberConsumer.sol"contract the "fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)" i.e "0.1 LINK"
        // Now this "RandomNumberConsumer.sol"contract has some Test Net link now we can call this "getRandomNumber" button because we can actually pay the ChainLink node to actually return our randnom number by confirming to transfer by paying...
        // ...little bit of "Transaction gas" to make the "requestRandomness()" using "getRandomNumber()" and then we're paying a little bit of "Oracle gas" to make the transaction so as to get "randomResult"...
        // ...but when we hit "randomResult" button it's still going to give zero. So why is that what's going on ?...as here getting a random number like this actually follows what's known as the "Request & Receive cycle" of getting data...
        // ... and we can read about it here:- "https://docs.chain.link/docs/architecture-request-model/"
        // So here in first transaction our "Smart Contract"(i.e Off-Chain) request some data(in this case a Random Number), and then in a second transaction the "Chainlink Node"(i.e On-Chain) itself will make a function call and return the data...
        // ...back to "Smart Contract" as "Response", In this case the function that we're calling is "fulfillRandomness()" which we had taken from
        // "https://remix.ethereum.org/#url=https://docs.chain.link/samples/VRF/RandomNumberConsumer.sol&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.7+commit.e28d00a7.js" i.e
        /*function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
            randomResult = randomness;
            }*/
        // Then after doing all this when we hit "randomResult" button now we can see indeed our random number is in here again the reason that it's in here is because we actually had "Asynchronous 2 transactions" occured...
        // ...one paid by us when we called "getRandomNumber" button
        // ...one paid by the Chainlink Node when it called "fulfillRandomness()"
        // Now lets add this "fulfillRandomness()" to our brownie project but before doing this first change the "lottery_state" of our model.

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        // Lets implement using code
        bytes32 requestId = requestRandomness(keyhash, fee); // this requestRandomness()....returns (bytes32 requestId)
        // So here in the "function endLottery() public onlyOwner{}" for our 1st transaction we're going to request the data from the "Chainlink Oracle" and...
        // ... in the second callback transaction, the "Chainlink Node" is going to return the data to this contract into another function called "fulfillRandomness()"...
        // ...So again if we look back in our "VRFConsumerBase.sol"(i.e."https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.6/VRFConsumerBase.sol")
        // we can see it has function "rawFulfillRandomness()":-
        // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF proof.
        // rawFulfillRandomness then calls fulfillRandomness, after validating the origin of the call
        /*
        function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
            require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
            fulfillRandomness(requestId, randomness);
            }
        */
        emit RequestedRandomness(requestId);
    }

    // 2nd Callback Transaction:-
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    /* 
        As we don't want anybody to call this function we only want our Chainlink Node to call this function,...
        ...So we can return a truly Random Number that's why here we making this "fulfillRandomness()" as an internal Function...
        ...because actually the Chainlink Node is calling the VRF Coordinator and then the VRFCoordinator is calling our fulfillRandomness()...
        ...and then we're going to give it a keyword of "override" and this means that we're overriding the original declaration of the "fulfillRandomness()",...
        ...Our "VRFConsumerBase.sol"(i.e "https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.6/VRFConsumerBase.sol")...
        ...has a function "fulfillRandomness()" which we can see it above also in comments, but it doesn't have any parameters or anything about this function,...
        ...actually laid out  and this function is meant to be overridden by us. So we exactly did the same by using keyword "override".
    */
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!" // If we're not reached till the lottery state then it will output this line.
        );
        require(_randomness > 0, "random-not-found"); // Doing another check to make sure we actually get a response.
        // Now we have to pick a random winner specifically out of our list of payable public players.
        // So our players array is just a list of players like [1, 2, 3, 4...] and each are at different index.
        // What we can do then to pick a random winner...So we have to do a Modulo Operation(or Mod Operation %) lets see an example in RemixIDE or view the code written in RemixIDE here
        /*
        pragma solidity^0.6.6;
        contract Mod{
            uint256 public number = 5;
            function doMod(uint256 modvalue) public view returns(uint256){
                return 5 % modvalue;
                } 
        // here we get two buttons "number" and "doMod" and on clicking on "number" we get to know that "number = 5" 
        // So here "doMOd" divides by the number and returns the remainder.
        } 
        */
        uint256 indexOfWinner = _randomness % players.length;
        // for example, Lets say we had 7 players signup and our random number was 22.
        // here we want to get one of these random 7 players, So we would do,
        // 22 % 7 = 1
        // 7 * 3 = 21
        // 7 * 4 = 28, this is how we know that we reached our upper limit.
        recentWinner = players[indexOfWinner];
        // Now we got a winner(i.e recentWinner) and we want to pay(or transfer) them all the money gathered from our "function enter() public payablbe{...}" to the "address" below here
        recentWinner.transfer(address(this).balance);
        // "Reset" the lottery so that we can start from scratch/blank again
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        // I often also like to keep track of the most recent random number
        randomness = _randomness;
    }
}

// Now let's do a "brownie compile" to check everything working good
// Lets now move into the Testing and Development phase and create a
// "deploy.py" script first in "scripts"  folder.
