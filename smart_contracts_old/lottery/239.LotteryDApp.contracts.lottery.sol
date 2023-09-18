pragma solidity ^0.4.2;
contract lottery
{
  address ticketowner;
  ticket[] public tickets;
  struct ticket
  {
   uint number;
   bytes32 date;
   uint  amount;
   bytes32 duedate;
   bytes32 ticket_owner;
   bytes32 ticket_status;
  }
  function create_ticket() public returns(uint)
  {
    for (uint i=0;i<5;i++)
    {
    ticket memory myticket;
    myticket.number=i;
    myticket.date= '0-0-0000';
    myticket.amount=100000;
    myticket.duedate='01-01-2018';
    myticket.ticket_owner ='00001';
    myticket.ticket_status='not sold';
    tickets.push(myticket);
    }
    return 1;
  }
  function show_ticket() public constant returns(uint[],bytes32[],uint[],bytes32[],bytes32[],bytes32[])
  {
    uint length = tickets.length;
    uint[] memory numbers = new uint[](length);
    bytes32[] memory dates = new bytes32[](length);
    uint[] memory amounts = new uint[](length);
    bytes32[] memory duedates = new bytes32[](length);
    bytes32[] memory owners = new bytes32[](length);
    bytes32[] memory stats = new bytes32[](length);
      for(uint i = 0; i < length; i++)
       {
        ticket memory newticket;
        newticket = tickets[i];
        numbers[i] = newticket.number;
        dates[i] = newticket.date;
        amounts[i] = newticket.amount;
        duedates[i] = newticket.duedate;
        owners[i] = newticket.ticket_owner;
        stats[i] = newticket.ticket_status;
       }
      return(numbers,dates,amounts,duedates,owners,stats);
  }
  function ticket_sale(uint num,bytes32 newid) public returns(uint)
    {
    for (uint i=0;i<5;i++)
     {
      if( tickets[i].number==num)
      {
        tickets[i].ticket_owner =newid;
        tickets[i].ticket_status='sold';
      }
    }
    return 1;
   }
   function  result() returns (bytes32)
   {
     uint winner;
     /*winner = Math.floor(Math.random() * 10) + 1;*/
     winner=uint(block.blockhash(block.number-1))%10 + 1;
     bytes32 win=tickets[winner].ticket_owner;
     return win;
   }

  }
