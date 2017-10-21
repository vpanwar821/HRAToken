pragma solidity ^0.4.15;

import './helpers/BasicToken.sol';
import './lib/safeMath.sol';

contract HRAsentToken is BasicToken{

    using SafeMath for uint256;

    string public name = "HRAsent";                             //name of the token
    string public symbol = "HRA";                               //symbol of the token
    uint8 public decimals = 10;                                 //decimals
    uint256 public totalSupply = 30000000 * 10**10              //total supply of Tokens

    //variables
    uint256 public foundersAllocation;                           //fund allocated to founders
    uint256 public devAllocation;                                //fund allocated to developers 
    uint256 public totalAllocatedTokens;                         //variable to keep track of funds allocated
    uint256 public tokensAllocatedToCrowdFund;                   //funds allocated to crowdfund

    //addresses
    address public founderMultiSigAddress;                      //Multi sign address of founders which hold
    address public devTeamAddress;                              //Developemnt team address which hold devAllocation funds
    address public crowdFundAddress;                            //Address of crowdfund contract

    //events
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp,address indexed _foundersWalletAddress);
    
    //modifierss

    modifier nonZeroAddress(address _to){
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders(){
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    //creation of token contract
    function HRAsentToken(address _crowdFundAddress, address _founderMultiSigAddress, address _devTeamAddress){
        crowdFundAddress = _crowdFundAddress;
        founderMultiSigAddress = _founderMultiSigAddress;
        devTeamAddress = _devTeamAddress


        // Assigned balances to respective stakeholders
        balances[msg.sender] = totalSupply;
    }

    //function to keep track of the total token allocation
    function changeTotalSupply(uint256 _amount){
        totalAllocatedTokens += _amount;
    }

    //function to change founder Multisig wallet address
    function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress){
        founderMultiSigAddress = _newFounderMultiSigAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

    //fallback function to restrict direct sending of ethers
    function(){
        revert();
    }

}