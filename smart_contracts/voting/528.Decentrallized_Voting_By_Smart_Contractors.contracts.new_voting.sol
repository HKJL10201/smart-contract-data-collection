// SPDX-License-Identifier: MIT

//Solidity compiler version
pragma solidity >= 0.6.0;

//Here the contract will start
contract New_Voting{
    

    //Struct function for the voter
    struct Voter{
        bool isVote; //checker variable to determine whether the voter has voted before
        address id; //ID of the voter        
        string towhom; //to whom the voter has voted
    }

    //Declaring and Initialising the variables for votes
    uint bjp = 0;
    uint congress = 0;
    uint aap = 0;
    uint nota = 0;

    //Initializing the time variable to the time of deployment
    uint time_inital = block.timestamp;
    uint time_final;
    //Setting total count of the variable to be zero
    uint counter = 0;

    //Declaring the static array to initialize the number of the vote
    Voter[1000] voters;

    //Initializing the ids of the voter via construction during the deployment
    constructor() {
        for (uint i = 0;i < 1000;i++){
            voters[i].id = msg.sender;
            voters[i].isVote = false;
            voters[i].towhom = "";
        }
        // time_inital = block.timestamp;
    }

    //Modifiers

    //Modifier used for comparing the current time and the
    //time of the declaration of the result
    // modifier Time(){
    //     require(block.timestamp >= time_inital + 30 seconds);
    //     _;
    // }
    
    //Modifier used for checking whether the voter is
    //giving his vote again
    modifier IsVote(uint i) {
        require(voters[i].isVote == false);
        _;
    }

    //Functions

    //Function to increase the vote count of BJP
    function BJP(uint i) public IsVote(i) {
        bjp++; //bjp counter will increases by one
        counter++; //Total count will increase by one
        voters[i].isVote = true; //Made the voter ineligible to vote
        voters[i].towhom = "BJP"; //Keeps the record of the voter list to whom the voter has voted
    }

    function Congress(uint i) public IsVote(i){
        congress++;
        counter++; //Total count will increase by one
        voters[i].isVote = true; //Made the voter ineligible to vote
        voters[i].towhom = "Congress"; //Keeps the record of the voter list to whom the voter has voted       
    }

    function AAP(uint i) public IsVote(i){
        aap++;
        counter++; //Total count will increase by one
        voters[i].isVote = true; //Made the voter ineligible to vote
        voters[i].towhom = "AAP"; //Keeps the record of the voter list to whom the voter has voted    
    }

    function NOTA(uint i) public IsVote(i){
        nota++;
        counter++; //Total count will increase by one
        voters[i].isVote = true; //Made the voter ineligible to vote
        voters[i].towhom = "None of the above"; //Keeps the record of the voter list to whom the voter has voted      
    }

    //This function will return the votes of BJP
    function VotesOfBJP() external view returns(uint) {
        return bjp;
    }

    //This function will return the votes of Congress
    function VotesOfCongress() external view returns(uint) {
        return congress;
    }

    //This function will return the votes of AAP
    function VotesOfAAP() external view returns(uint) {
        return aap;
    }

    //This function will return the votes of None of the above
    function VotesOfNOTA() external view returns(uint) {
        return nota;
    }

    //This function finally declares the result of the all the candidates
    //registered to be voted and the total voting of the elections
    function Declaration() external view returns(uint){
        return counter;
    }

    function Winner() external view returns(uint){
        uint[4] memory candidates;
        candidates[0] = bjp;
        candidates[1] = congress;
        candidates[2] = aap;
        candidates[3] = nota;
        uint max = bjp;
        for (uint i = 0;i < 4;i++){
            if (candidates[i] > max) max = candidates[i];
        }
        return max;
    }

}