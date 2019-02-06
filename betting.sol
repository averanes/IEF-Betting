pragma solidity ^0.5.2;


contract IEF_Betting {
    
    
    struct PlayerBet {
        // which value the player bet on
        uint8 bet;
        uint256 timestamp;
    }
    
    struct Bet {
        // stores the address of the creator of the bet
        address betOwner;
        // stores all the bets made by any player
        mapping(address => PlayerBet) bets;
        address payable [] players; 
        // the amount of the bet, this is set at the bet creation
        uint256 ETHAmount;
        // the timestamp when the bet will be closed at the latest
        uint256 latestClosage;
        // the timestamp for the earliest closage by the owner
        uint256 earliestClosage;
        // the timestamp when the bet was created
        uint256 openedAt;
        // can players still bet on this bet
        bool isOpen;
        // the randomly generated result (0 or 1)
        int8 randomResult;
        // number of persons who bet for 0
        uint peopleOn0;
        // number of persons who bet for 1
        uint peopleOn1;
    }
    
     mapping(uint256 => Bet) public betting;
     // contains the latest created betID:
     uint256 public betId;
    
    // owners of the contract (and the betting system)
    address payable [] public betOwners;
    
    modifier onlyOwner {
        for(uint index = 0; index < betOwners.length; index++) {
            if (msg.sender == betOwners[index]){
                   _;
                return;
              }
        }
        revert(); 
    }
    
    function addOwners(address payable user) onlyOwner public {
        betOwners.push(user);
    }
    
    constructor() public {
        betOwners.push(msg.sender);
        betId = 0;
    }
    
    function checkLastBetIdForOwner() onlyOwner view public returns (uint256 lastBetId) {
        
        for(uint256 x = betId; x > 0; x--) {
            if(betting[x].betOwner == msg.sender){
                
                lastBetId = x;
                return lastBetId;
            }
        }
        
       return lastBetId;
    }
    
    function createBet(uint256 ethAmount, uint256 minHoursOpen, uint256 maxHoursOpen) onlyOwner public returns (uint256) {
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
    
    function closeBet(uint256 id) onlyOwner public returns (bool) {
        require(betting[id].isOpen);
        // bet cannot be closed before the earliestClosage
        require(now > betting[id].earliestClosage);
        
        //BEGIN: random 0 1 generator
        betting[id].randomResult = int8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 2);
        //END: random 0 1 generator
        
        //BEGIN: rewards distribution
        //the vars totalAmountSetFor0-1 are unnecesaries
        uint totalAmount = betting[id].players.length * (1e18 * betting[id].ETHAmount);
        uint ownerPercentage = totalAmount / 100;
        totalAmount -= ownerPercentage;
        uint no_winners = betting[id].randomResult == 0 ? betting[id].peopleOn0 : betting[id].peopleOn1;
        
        //to divide the profit among all owners
        ownerPercentage = ownerPercentage / betOwners.length;
        for(uint index = 0; index < betOwners.length; index++) {
             betOwners[index].transfer(ownerPercentage);
        }
        
        for(uint index = 0; index < betting[id].players.length; index++) {
            address payable current = betting[id].players[index];
            
            if(betting[id].bets[current].bet == uint(betting[id].randomResult))
                current.transfer(totalAmount / no_winners);
        }
        //END: rewards distribution
        
        betting[id].isOpen = false;
        return true;
    }
    
    // PD: Perfect timeout and random algorithm needs use a Oracle
}
