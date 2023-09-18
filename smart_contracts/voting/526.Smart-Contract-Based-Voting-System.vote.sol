// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Voting2
{
    struct Candidates{
        string c_name;
        uint age;
        uint p_no;

    }

    struct Voters{
        string v_name;
        uint age;
        uint ticket;
        bool voted;
    }
    address public manager;
    function Manager() public
    {
        manager=msg.sender;
    }
    mapping(string=>Candidates) public candidates;
    mapping(string=>Voters) public voters;
    uint[25] public arr;

    function x() public
    {
        for(uint i=0;i<25;i++)
        {
            arr[i]=0;
        }
    }
    function addCandidate(string memory c_name,uint age,uint party_no) public
    {
        candidates[c_name]=Candidates(c_name,age,party_no);
    }

    function addVoter(string memory v_name,uint age) public
    {
        require(age>=18);
        voters[v_name]=Voters(v_name,age,1,false);
    }

    function Vote(string memory v_name,uint party_no) public
    {
        require(voters[v_name].voted==false);
        require(voters[v_name].ticket==1);
            arr[party_no]+=1;
            voters[v_name].voted=true;
            voters[v_name].ticket=0;
    }

 function Winner() public view returns(uint)
    {
        uint z=0;
            uint k;
            for(k=0;k<arr.length;k++)
            {
                if(arr[k]>arr[z])
                {
                    z=k;
                }
            }
            return z;
  }

}