// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


//@todo use file pattern for admin calls
//@todo combine already voted and single address together

//@note using merkletree for main logic

import "lib/solmate/src/utils/MerkleProofLib.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "forge-std/console.sol";

contract Voting is Ownable2Step{


    //errors

    error NotStart();
    error invalidVoter(address _caller);

    //If you want to add a single address

    //@note   Use bitmaps later https://solodit.xyz/issues/5953 (once I understand it completely)

    
    mapping(address => uint256) public singleAddress;
    mapping(address => uint256) public isVoted;

    //Candidate Name
    mapping(string => uint256) public votes;

    //root Hash
    bytes32 public rootHash;

    //When to Start
    uint64 timeToStart; 

    event Vote(address voter);



    //@note: timeToStart should be unix timestamp on when to start

    constructor(bytes32 _rootHash,uint64 _timeToStart){
        rootHash = _rootHash;

        timeToStart = _timeToStart;

    }







    //Does not check  whether the candidate name is accurate
    function vote(bytes32[] calldata proof , string calldata candidate) external {
        if(uint64(block.timestamp) < timeToStart  ){
            revert NotStart();
        }
        if((!verify(proof,msg.sender) && singleAddress[msg.sender]!=1) || isVoted[msg.sender] == 1 ){
            revert invalidVoter(msg.sender);
        }

        ++votes[candidate];
        isVoted[msg.sender] = 1;
        emit Vote(msg.sender);

    }

    //using public because so users can check whether their are registered vote in the hashedroot
    //@param proof: the proof array ordereds
    //@param leaf: the leaf (the address)
    //@returns : returns bool if it is valid address
    function verify(bytes32[] calldata proof,address _addy) public view returns(bool) {

        
        return(MerkleProofLib.verify(proof,rootHash,keccak256(bytes.concat(keccak256(abi.encode(_addy))))));

    }

        /* -------------------------------------------------------------------
       |                      Owner                                         |
       |  ___________________________________________________________   _____ | */






    //@note if _value = 1 then true but any other value its false 
    //@note make sure not to use 0 to save gas (use for example 2 to set it to false)
    //@note recommended to use 2 to set it false



    function updateSingle(address _addy,uint8 _value) external onlyOwner{
        singleAddress[_addy] = _value;
    }

    function updateRootHash(bytes32 _rootHash) external onlyOwner{
        rootHash = _rootHash;
    }

    // You can use this as a force stop by setting the time stamp to a value far into the future or start early by setting to a closer value
    //@note: timeToStart should be unix timestamp on when to start 
    
    function updateTimeStamp(uint64 _timeToStart) external onlyOwner{
        timeToStart =  _timeToStart;
    }


    
}
