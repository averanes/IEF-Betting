pragma solidity ^0.5.2;

contract IEF_Betting {
    
    struct PlayerBet {
        uint8 bet;
        uint256 timestamp;
    }
    
    struct Bet {
        address payable betOwner;
        mapping(address => PlayerBet) bets;
        address payable [] players; 
        uint256 ETHAmount;
        uint256 latestClosage;
        uint256 earliestClosage;
        uint256 openedAt;
        bool isOpen;
        int8 randomResult;
        uint peopleOn0;
        uint peopleOn1;
    }
    
    mapping(uint256 => Bet) public betting;
    uint256 public betId;
    
    constructor() public {
        betId = 0;
    }
    
    function createBet(uint256 ethAmount, uint256 minHoursOpen, uint256 maxHoursOpen) public returns (uint256) {
        require(minHoursOpen < maxHoursOpen);
        
        betId++;
        Bet memory bet = Bet({
            betOwner:msg.sender,
            ETHAmount:ethAmount,
            players: new address payable[](0),
            // convert days to seconds
            earliestClosage: now + (minHoursOpen * 60 * 60),
            latestClosage: now + (maxHoursOpen * 60 * 60),
            openedAt: now,
            isOpen:true,
            randomResult:-1,
            peopleOn0:0,
            peopleOn1:0
        });
        betting[betId] = bet;
        return betId;
    }
    
    function placeBet(uint256 id, uint8 val) payable public returns (bool){
        // check if bet is opened 
        // check if a playerbet does not already exist
        // check if the correct amount of ETH was sent
        // check if it was bet for either 0 or 1, other values are not allowed
        if(!betting[id].isOpen
            || betting[id].bets[msg.sender].timestamp != 0
            || msg.value != (1e18 * betting[id].ETHAmount)
            || (val != 0 && val != 1)) {
            // refund
            msg.sender.transfer(msg.value);            
            return false;        
        }
        
        PlayerBet memory bet = PlayerBet({
           bet:val,
           timestamp:now
        });
        
        betting[id].bets[msg.sender] = bet;
        // add the player to the bet 
        betting[id].players.push(msg.sender);
        
        if(val == 0) {
            betting[id].peopleOn0++;
        } else {
            betting[id].peopleOn1++;
        }
        
        return true; 
    }
    
    function closeBet(uint256 id) public returns (bool) {
        require(betting[id].isOpen);
        // bet cannot be closed before the earliestClosage
        require(now > betting[id].earliestClosage);
        require(betting[id].betOwner == msg.sender);
        
        betting[id].isOpen = false;
        
        //BEGIN: random 0 1 generator
        betting[id].randomResult = int8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 2);
        //END: random 0 1 generator
        
        //BEGIN: rewards distribution
        //the vars totalAmountSetFor0-1 are unnecesaries
        uint totalAmount = betting[id].players.length * (1e18 * betting[id].ETHAmount);
        uint ownerPercentage = totalAmount / 100;
        totalAmount -= ownerPercentage;
        uint no_winners = betting[id].randomResult == 0 ? betting[id].peopleOn0 : betting[id].peopleOn1;
        
        betting[id].betOwner.transfer(ownerPercentage);
        
        for(uint index = 0; index < betting[id].players.length; index++) {
            address payable current = betting[id].players[index];
            
            if(betting[id].bets[current].bet == uint(betting[id].randomResult))
                current.transfer(totalAmount / no_winners);
        }
        //END: rewards distribution
        
        return true;
    }
    
    
    // TODO: create a timeout that automatically closes the bets
}
