// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Auction{

    bool isEnded;
    address payable auctionOwner; //دي عشان احفظ مين صاحب المزاد
    uint public endTime; // دي عشان احفظ اخر وقت

    uint public highestBid; //دي عشان احفظ فيها اعلي قيمه اتدفعت
    address public highestBidder; // ودي عشان احفظ الشخص اللي دفع اعلي قيمه

    //الايفنت ده عشان يشوف اعلي شخص دفع حتي الان
    event getHighestBidder(address bidder, uint amount);

    event auctionWinner(address winner, uint amount);

    mapping(address=>uint)bidderContributers; // دي عشان احفظ فيها كل اللي شارك في المزاد

    constructor(uint _timeInSecond, address payable _auctionOwner){
        endTime = block.timestamp + _timeInSecond; // بجيب اخر وقت للبلوك و بضيف عليه عدد الثواني
        auctionOwner = _auctionOwner; // بحفظ صاحب المزاد
    }

    function bid()public payable{
        if(block.timestamp > endTime) revert("Auction has ended"); // ده عشان يتشك علي ان الوقت الحالي اكبر  من اخر وقت تم استخدامه لل مزاد ده
        //ده هيشوف القيمه اللي داخله دي لو اصغر من اخر قيمه اتدفعت هيطلع ايرور
        if(msg.value <= highestBid) revert("Sorry you need to incress amount");
        // طبعا لو عدا من الاتشيك ده خلاص بقا يبقا هو اعلي من اخر واحد ف هيضيفه
        bidderContributers[highestBidder] += highestBid;

        highestBid = msg.value; //هحقظ القيمه الجديده بقا
        highestBidder = msg.sender; // مع الشخص الجديد

        //هحدد الشخص الاخير اللي دفع عشان طبعا ده هيبقا اعلي شخص دفع حتي الان
        emit getHighestBidder( msg.sender,msg.value);
    }

    function withdraw() public payable returns(bool){
        uint amount = bidderContributers[msg.sender]; // هنا بجيب من اللي شاركم في المزاد
         // بشوف لو الفلوس بتاعتهم اكبر من صفر يبقا هما ليهم فلوس
        if(amount>0){
            bidderContributers[msg.sender] = 0;
        }
        // هنا بشوف لو عمليه استرجاع الفلوس منجحتش هرجعلهالفلوس تاني
        if(!payable(msg.sender).send(amount)){
            bidderContributers[msg.sender] = amount;
        }

        return true;
    }

    //عشان تنهي العقد
    function endAuction()public {
        //بتشك علي ان العقد لو لسه منتهاش يرجع خطأ
        if(block.timestamp < endTime) revert("The auction runing.., not ended yet.");
        
        //وهنا اول اما العقد بيتنهي بعدل القيمه ل ترو ف بالتالي  لما يجي يتشك هيلاقيه انتهي ف هيرجع ان هو انتهي
        if(isEnded) revert("Auction Ended");
        isEnded = true;

        // بحول اعلي قيمه لصاحب المزاد
        auctionOwner.transfer(highestBid);

        // بشغل ايفنت بتاع الشخص اللي فاز بالمزاد
        emit auctionWinner(highestBidder, highestBid);

    }
}
