pragma solidity ^0.5.2;

contract IEF_Betting {
    
    struct PlayerBet {
        uint8 bet;
        uint256 timestamp;
    }
    
    struct Bet {
        address betOwner;
        mapping(address => PlayerBet) bets;
        address[] players; 
        uint256 ETHAmount;
        uint256 latestClosage;
        uint256 earliestClosage;
        uint256 openedAt;
        bool isOpen;
        int8 randomResult;
        uint256 totalAmountSetFor0;
        uint256 totalAmountSetFor1;
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
            players: new address[](0),
            // convert days to seconds
            earliestClosage: now + (minHoursOpen * 60 * 60),
            latestClosage: now + (maxHoursOpen * 60 * 60),
            openedAt: now,
            isOpen:true,
            randomResult:-1,
            totalAmountSetFor0:0,
            totalAmountSetFor1:0
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
            betting[id].totalAmountSetFor0 = betting[id].totalAmountSetFor0 + betting[id].ETHAmount;
        } else {
            betting[id].totalAmountSetFor1 = betting[id].totalAmountSetFor1 + betting[id].ETHAmount;
        
        }
        
        return true; 
    }
    
    function closeBet(uint256 id) public returns (bool) {
        // TODO: determine the random number 0/1
        // TODO: reward the winners of the bet with the ether
        
        require(betting[id].isOpen);
        // bet cannot be closed before the earliestClosage
        require(now > betting[id].earliestClosage);
        require(betting[id].betOwner == msg.sender);
        betting[id].isOpen = false;
        return true;
    }
    
    
    // TODO: create a timeout that automatically closes the bets
}