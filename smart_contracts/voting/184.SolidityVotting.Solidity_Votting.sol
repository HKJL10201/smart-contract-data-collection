// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Votting{

    address public Owner;

    enum FAZ{
        PreStart,//0
        Start,//1
        End//2
    }

    FAZ public fazes;

    struct Candida{
        uint8 id;
        uint8 CountVote;
        string name;
    }

    struct Votter{
        string name;
        bool Vote;
        uint8 CandidIDvotted;
    }

    Candida[] public candida; 
    mapping(address => Votter) public VotterINFO;

    uint8 Counter;

    constructor(){
        Owner = msg.sender;
        fazes = FAZ.PreStart;
    }

    modifier OwnerCheck(){
        require(Owner == msg.sender,"Only Owner...");
        _;
    }

    function ChangFaz(uint8 code) public OwnerCheck(){
        if(code == 1){
            fazes = FAZ.Start;
        }else{
            fazes = FAZ.End;
        }
    }

    function AddCandida(string memory name) public OwnerCheck(){
        require(fazes == FAZ.PreStart,"Only PreStart Faz...");
        candida.push(Candida(Counter,0,name));
        Counter++;
    }

    function VottingCandida(string memory name, uint8 CandidaID) public {
        require(fazes == FAZ.Start,"Only Start Faz...");
        require(VotterINFO[msg.sender].Vote == false,"only one Can Votted...");
        VotterINFO[msg.sender] = Votter(name,true,CandidaID);
        candida[CandidaID].CountVote++;
    }

    function WinCandida() public view returns(uint8, string memory){
        require(fazes == FAZ.End,"Only End Faz...");
        uint maximum = 0;
        uint8 WinIndex = 0;

        for(uint8 i=0;i<candida.length;i++){
            if(candida[i].CountVote>maximum){
                maximum = candida[i].CountVote;
                WinIndex = i;
            }
        }
        
        return (WinIndex, candida[WinIndex].name);
    }
    
}
