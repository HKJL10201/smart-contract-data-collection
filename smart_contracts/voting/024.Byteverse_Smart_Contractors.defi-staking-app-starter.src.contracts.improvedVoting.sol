pragma solidity > 0.5.0;

contract voting{
    uint public a;
    uint public b;
    uint public c;

    constructor() public {
        a=0;
        b=0;    
        c=0;
    }
    
    
    function voteA() public{
        a++;
    }
    function voteB() public{
        b++;
    }
    function voteC() public{
        c++;
    }
    function winner() view public returns(string memory){

        if(a==0 && b==0 && c==0){
            return 'voting is not started';
        }
        if(a>b&&a>c){
            return 'a wins';
        }
        if(c>b&&c>a){
               return 'c wins';
        }
        if(b>a&&b>c){
            return 'b wins';
        }
          else{
           if(a==b){
               return 'A and B draws';
           }
           if(b==c){
               return 'B and C draws';
           }
           if(a==c){
               return 'A and C draws';
           }
          if(a==b && b==c){
              return 'no party wins';
          }
       }
    }
}