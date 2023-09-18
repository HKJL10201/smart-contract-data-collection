// Uses a solidity version above the one specified i.e specifies bare minimum
pragma solidity ^0.5.8;

// Solidity contract for the lottery
contract Lottery {
    
    address payable public managerAddress;
    address payable public previousLotteryWinner;
    uint public totalWinningChance;
    
    struct chanceStruct{
        uint currChances;
        bool validEntry;
    }
    
    address payable[] public memberList;
    mapping(address => chanceStruct) winningChances;
    
    // msg is a built-in global variable containing fields with transaction info
    constructor() public{
        // Set manager address to be the same as contract creator
        managerAddress = msg.sender;
        previousLotteryWinner = managerAddress;
        totalWinningChance = 0;
    }
    
    // This function is payable because it needs ether to be sent to it for registering
    function registerForLottery() public payable {
        require(msg.value > 0.1 ether);
        
        uint newChance = uint((msg.value)/(100000000000000000));
        
        if(winningChances[msg.sender].validEntry) {
            // Entry exists and needs to have winning chances modified
            winningChances[msg.sender].currChances += newChance;
        }
        else {
            // Entry doesnt exist for this sender address, so create it
            chanceStruct memory tempStruct;
            tempStruct.currChances = newChance;
            tempStruct.validEntry = true;
            
            winningChances[msg.sender] = tempStruct;
            memberList.push(msg.sender);
        }
        
        // Increment total win chances
        totalWinningChance += newChance;
    }
    
    function getCurrentWinningChances() public view returns (uint, uint){
        // Returns winning chances for message sender if they exist, otherwise returns 0
        // Percent calculations need to be handled in the client
        address queryMember = msg.sender;
        if(winningChances[queryMember].validEntry && totalWinningChance != 0) {
            return (winningChances[queryMember].currChances,totalWinningChance);
        }
        else
            return (0,0);
    }
    
    function getAllWinningChances() public view returns (address payable[] memory, int[] memory) {
        // Get winning chances of all registered members - Useful for leaderboard and pie chart generation
        uint totalLength = memberList.length;
        
        int[] memory returnChanceList = new int[](totalLength);
        address payable[] memory returnMemberList = new address payable[](totalLength);
        
        for (uint i=0; i<memberList.length; i++) {
            address payable currPlayer = memberList[i];
            int currChance = int(winningChances[currPlayer].currChances);
            returnMemberList[i] = currPlayer;
            returnChanceList[i] = currChance;
        }
        return (returnMemberList, returnChanceList);
    }
    
    // Note: NOT A RELIABLE RNG. There are ways of gaming the lottery system if this is used. Should suffice for now though.
    function genPseudoRandom() view private returns (uint256) {
        // keccak256 is the new sha3, block and now are new global vars similar to msg
        return uint256(keccak256(abi.encodePacked(block.difficulty, now, memberList)));
    }
    
    // Restricted to just the manager via modifier
    function pickLotteryWinner() public restrictedToManager {
        // Selects a winner randomly (almost!)
        int winningValue = int(genPseudoRandom() % totalWinningChance);
        address payable lotteryWinner;


        for(uint i=0; i<memberList.length; i++){
            address payable currPlayer = memberList[i];
            int currChance = int(winningChances[currPlayer].currChances);

            winningValue -= currChance;
            if(winningValue <= 0){
                lotteryWinner = currPlayer;
                break;
            }
            else if(i == memberList.length - 1)
                lotteryWinner = currPlayer;
         }

        lotteryWinner.transfer(address(this).balance);
        
        // Resets the member list to enable next round of lottery
        uint memberLength = memberList.length;
        for(uint i=0; i<memberLength; i++){
            address currEntry = memberList[i];
            winningChances[currEntry].currChances = 0;
            winningChances[currEntry].validEntry = false;
        }
        
        // Log current winner in the contract
        memberList = new address payable[](0);
        totalWinningChance = 0;
        previousLotteryWinner = lotteryWinner;
    }

    // Kills the lottery contract provided its empty
    function shutDownLottery() public payable restrictedToManager {
        // Check for empty contract
        require(totalWinningChance == 0 && memberList.length == 0);
        
        selfdestruct(managerAddress);
    }
    
    // In general, arrays when declared as public do get an inbuilt helper func, but it can access only one member at a time. Hence this.
    // Returns a list of unique lottery members
    function returnRegisteredMembers() public view returns(address payable[] memory){
        return memberList;
    }
    
    // _ is the place where code from the function using this modifier is substituted
    modifier restrictedToManager() {
        require (msg.sender == managerAddress);
        _;
    }
    
}