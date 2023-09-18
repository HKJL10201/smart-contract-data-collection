// SPDX-License-Identifier:MIT
pragma solidity ^0.8.1;
contract PollingDapp{
    address payable admin;
    constructor(){
        admin = payable(msg.sender);
    }
    modifier OnlyAdmin{
        require(msg.sender == admin);
        _;
    }
    struct Participent{
        string Name;
        uint count;
        address from;
        string VotingRec;    
        string imageLink;
    }
    struct News{
        string title;
        uint timestamp;
        string Description;
    }
    News[] NNews;
    Participent[] Participents;
    address[] VotedPeople;
    address[] RegistredParticipent;
    function InputParticipent(string memory Name,address pk,string memory VotingRec,string memory link) public payable OnlyAdmin{
        require(CheckAlreadyParticipated(pk),"Already Reg");
        require(msg.value >0 ,"please pay 0>");
        uint number =0;
        admin.transfer(msg.value);
        Participents.push(Participent(Name,number,pk,VotingRec,link));
        RegistredParticipent.push(pk);
    }
    function CheckAlreadyParticipated(address pubkey) public view returns(bool){
         for(uint i=0;i<RegistredParticipent.length;i++){
             if(RegistredParticipent[i]==pubkey){
                 return false;
             }
         }
         return true;
    }
    function SelectVote(address PartiAdd) public{
        require(AlreadyReg(msg.sender),"Already VOted");
        for(uint i=0;i<Participents.length;i++){
            if(Participents[i].from == PartiAdd){
                Participents[i].count++;
            }
        }
        VotedPeople.push(msg.sender);
    }
    function AlreadyReg(address pubkey) public view returns(bool){
        for(uint i=0;i<VotedPeople.length;i++){
            if(VotedPeople[i]==pubkey){
                return false;
            }
        }
        return true;
    }
    function GetData() public view returns(Participent[] memory){
        return Participents;
    }
    function PostNews(string memory title,string memory Des) public OnlyAdmin{
        NNews.push(News(title,block.timestamp,Des));
    }
    function GetNews() public view returns(News[] memory){
        return NNews;
    }
}