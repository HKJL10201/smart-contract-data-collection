// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract SocialRecovery {
    struct GuardianInfo {
        uint index;
        bool exists;
        bool activated;
        uint activateTime;
        uint deleteTime;
    }
    
    mapping(address => GuardianInfo) guardians;
    address[] existingGuardianList;
    address[] activatedGuardianList;
    address owner;
    mapping (address => uint) newOwnerVotings;
    mapping(address => address) guardianVoteInfo;
    uint numActiveGuardians;

    event CreateWallet();
    event SuccessFullVote();
    event GuardianAdded();

     modifier onlyOwner() {
        require(owner == tx.origin, "Only Owner has entitlements to perform this action");
        _;
     }
    constructor(address[] memory _guardians) public {
        numActiveGuardians = _guardians.length;
        activatedGuardianList = _guardians;
        existingGuardianList = _guardians;
        for (uint i = 0; i < numActiveGuardians; i++) {
            guardians[_guardians[i]].exists = true;
            guardians[_guardians[i]].activated = true;
            guardians[_guardians[i]].index = i;
        }
        owner = tx.origin;
        emit CreateWallet();
    }

    /* External Functions */
    function castVote(address newOwnerAddress) external returns(bool) {
        bool isOwnerChanged;
        require(guardians[tx.origin].exists, "Only Guardian can cast vote");
        require(isGuardianEligibleToVote(), "Guardian need to be activated to participate in voting");
        require(guardianVoteInfo[tx.origin] == address(0)  , "Already casted vote, to cast a new vote delete the previous vote");
        require(owner != newOwnerAddress, "New owner address matches the old owner");
        newOwnerVotings[newOwnerAddress] +=1;
        guardianVoteInfo[tx.origin] = newOwnerAddress;
        if (4 * newOwnerVotings[newOwnerAddress]>numActiveGuardians*3) {
            setNewOwner(newOwnerAddress);
            isOwnerChanged = true;
        }
        return isOwnerChanged;
    }

    function removeVote(address guardianAddress) public {
        require(guardianVoteInfo[guardianAddress] != address(0)  , "Need to cast vote to delete.");// can be changed based on UI design
        newOwnerVotings[guardianVoteInfo[guardianAddress]] -=1;
        delete guardianVoteInfo[guardianAddress];
    }

    function initiateAddGuardian(address newGuardian)external onlyOwner{
        guardians[newGuardian].exists = true;
        guardians[newGuardian].activateTime = block.timestamp + 10 seconds;
        existingGuardianList.push(newGuardian);

    }

    function activateGuardian(address newGuardianAddress) external {
        require(guardians[newGuardianAddress].activateTime < block.timestamp, "Guardian not yet activate to Vote");
        numActiveGuardians +=1;
        activatedGuardianList.push(newGuardianAddress);
        guardians[newGuardianAddress].activateTime = 0;
        guardians[newGuardianAddress].activated = true;
        guardians[newGuardianAddress].index = numActiveGuardians -1;
        
    }

    function initiateGuardianRemoval(address removeGuardianAddress) external onlyOwner {
        require(guardians[removeGuardianAddress].exists, "No such guardian exists");
        require(guardians[removeGuardianAddress].deleteTime != 0, "Removal of this guardian is not initiated");
        guardians[removeGuardianAddress].deleteTime = block.timestamp + 10 seconds;
    }

    function removeGuardian(address removeGuardianAddress) external onlyOwner {
        require(guardians[removeGuardianAddress].deleteTime !=0, "Need to initiate removal first");// we can remove based on UI design
        require(guardians[removeGuardianAddress].deleteTime < block.timestamp , "Need to initiate removal first");
        if(guardianVoteInfo[removeGuardianAddress] != address(0)){
            removeVote(guardianVoteInfo[removeGuardianAddress]);
        }
        if(guardians[removeGuardianAddress].activated){
            uint idx = guardians[removeGuardianAddress].index;
            GuardianInfo storage lastGuardianInfo = guardians[activatedGuardianList[numActiveGuardians-1]];
            lastGuardianInfo.index = idx;
            activatedGuardianList.pop();
        }
        uint i;
        for(i;i<existingGuardianList.length;i++){
            if(existingGuardianList[i] == removeGuardianAddress){
                break;
            }
        }
        existingGuardianList[i] = existingGuardianList[existingGuardianList.length-1];
        existingGuardianList.pop();
        numActiveGuardians -=1;
        delete guardians[removeGuardianAddress];
    }

    /** Internal Functions */

    function isGuardianEligibleToVote() internal view returns(bool isEligible){
        return guardians[tx.origin].activated;
    }

    function setNewOwner(address newOwnerAddress) internal{
        owner = newOwnerAddress;
        delete newOwnerVotings[newOwnerAddress];
        for(uint i=0;i<numActiveGuardians;i++){
            delete guardianVoteInfo[activatedGuardianList[i]];
        }
    }

    function fetchExistingList() public view returns (address[] memory){
        return existingGuardianList;
    }

    function fetchGuardianStatus(address guardianAddress)public view returns ( bool){
        return guardians[guardianAddress].activated;
    }

}
