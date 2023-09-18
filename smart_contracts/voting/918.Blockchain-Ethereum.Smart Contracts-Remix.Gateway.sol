// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Gateway {
    
    mapping(address=>uint) public ownersWallet;    //wallet balance
    mapping(address=>bool) public createdUser;      //createdUser--checks if a User/address exists
    
    function addAccount() public payable returns(string memory)
    {
        
        require(createdUser[msg.sender]==false);
        if(msg.value==0){
          ownersWallet[msg.sender]=0;
          createdUser[msg.sender]=true;
          return 'New account has been created with balance 0';
        }

        require(createdUser[msg.sender]==false);
        ownersWallet[msg.sender] = msg.value;
        createdUser[msg.sender] = true;
        return 'New account created account created';
    }

    function etherDepo() public payable returns(string memory){
      require(createdUser[msg.sender]==true);   //user=msg.sender else account is non-existent.
      require(msg.value>0, 'value is zero: re-check');
      ownersWallet[msg.sender]=ownersWallet[msg.sender]+msg.value;
      return ('Ether has been Deposited to wallet');
      //return createdUser[msg.sender];
    }

    function etherWithd(uint request) public payable returns(string memory){
      require(ownersWallet[msg.sender]>request, 'insufficeint balance');
      require(ownersWallet[msg.sender]>1, 'cannot withdraw below minimum balance limit');
      require(request>0);
      require(createdUser[msg.sender]==true);
      
      ownersWallet[msg.sender]=ownersWallet[msg.sender]-request;
      payable(msg.sender).transfer(request);
      return 'Ether withdrawal completed';
    }

    function etherTransfer(address payable receiver, uint request) public returns(string memory,uint){
      require(ownersWallet[msg.sender]>request);    //ensure there is enough ether in wallet for the transfer
      require(createdUser[msg.sender]==true);
      require(createdUser[receiver]==true, 'recipient does not exist');
      require(request>0);
      ownersWallet[msg.sender]=ownersWallet[msg.sender]-request;
      ownersWallet[receiver]=ownersWallet[receiver]+request;    //receiver=receiver's address
      return ('Ether has been transfered to Recipient Wallet',ownersWallet[msg.sender]);
      //return ownersWallet[msg.sender];
    }

    function viewBalance() public view returns(uint){
      return ownersWallet[msg.sender];
  }




}
