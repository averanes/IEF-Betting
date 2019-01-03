pragma solidity ^0.5.2;

contract IEF_Betting {
    
    struct PlayerBet {
        uint8 bet;
        uint256 timestamp;
    }
    
    struct Bet {
        address betOwner;
        mapping(address => PlayerBet) bets;
        uint256 ETHAmount;
        uint256 latestClosage;
        bool isOpen;
    }
    
    mapping(uint256 => Bet) public betting;
    uint256 public betId;
    
    constructor() public {
        betId = 0;
    }
    
    function createBet(uint256 ethAmount, uint256 maxDaysOpen) public returns (uint256) {
        betId++;
        Bet memory bet = Bet({
            betOwner:msg.sender,
            ETHAmount:ethAmount,
            // convert days to seconds
            latestClosage: now + (maxDaysOpen * 24 * 60 * 60),
            isOpen:true
        });
        betting[betId] = bet;
        return betId;
    }
    
    function placeBet(uint256 id) public returns (bool){
        // TODO: return refunds if bet is already closed
        // TODO: make payable function
        
        require(betting[id].isOpen);
        // check if bet does not already exist
        require(betting[id].bets[msg.sender].timestamp > 0);
        
        PlayerBet memory bet = PlayerBet({
           bet:1,
           timestamp:now
        });
        
        betting[id].bets[msg.sender] = bet;
        return true; 
    }
    
    function closeBet(uint256 id) public returns (bool) {
        // TODO: determine the random number 0/1
        // TODO: reward the winners of the bet with the ether
        
        require(betting[id].isOpen);
        require(betting[id].betOwner == msg.sender);
        betting[id].isOpen = false;
        return true;
    }
    
    
    // TODO: create a timeout that automatically closes the bets
}