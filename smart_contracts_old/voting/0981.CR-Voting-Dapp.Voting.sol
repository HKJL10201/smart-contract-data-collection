pragma solidity ^0.4.25;
contract CollegeVoting
{
    string[] public Roll_Numbers;
    int[] public candidates=[1,2,3,4];
    string Roll_exists;
    string extract;
    address owner;
    int  c1=0;
    int  c2=0;
    int  c3=0;
    int  c4=0;
    string public FinalResult;
    modifier OnlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    constructor() public{
        owner = msg.sender;
    }
    function  add_rollno(string Roll_No) public OnlyOwner
    {
        Roll_Numbers.push(string(Roll_No));
    }
    function add_Candidates(int can_name) public OnlyOwner
    {
        candidates.push(int(can_name));
    }
    function Rno_Cno(string Ro , int can) public
    {
        for(uint i=0;i<Roll_Numbers.length;i++)
        {
            extract = Roll_Numbers[i];
            if(keccak256(extract)==keccak256(Ro))
            {
            for(uint j = i;j<Roll_Numbers.length-1;j++){
                    Roll_Numbers[j] = Roll_Numbers[j+1];
                    
            }
            delete Roll_Numbers[Roll_Numbers.length-1];
            Roll_Numbers.length--;
                    if(can==1)
                    {
                       c1++; 
                    }
                    else if(can==2)
                    {
                        c2++;
                    }
                    else if(can==3)
                    {
                        c3++;
                    }
                    else if(can==4)
                    {
                        c4++;
                    }
                    break;
            }
        }
    }
    function result() public OnlyOwner
    {
      
            if(c1>c2 && c1>c3 && c1>c4)
            {
                FinalResult='c1';
            }
            else if(c2>c1 && c2>c3 && c2>c4)
            {
                FinalResult='c2';
            }
            else if(c3>c1 && c3>c2 && c3>c4)
            {
                FinalResult='c3';
            }
           else if(c4>c1 && c4>c2 && c4>c3)
            {
                FinalResult='c4';
            }
            else
            {
                FinalResult='no vote is recorded yet';
            }
            
    }
}
