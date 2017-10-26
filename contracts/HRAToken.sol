pragma solidity ^0.4.15;

import './helpers/BasicToken.sol';
import './lib/safeMath.sol';

contract HRAToken is BasicToken {

    using SafeMath for uint256;

    string public name = "HERA";                                //name of the token
    string public symbol = "HRA";                               //symbol of the token
    uint8 public decimals = 10;                                 //decimals
    uint256 public initialSupply = 30000000 * 10**10;             //total supply of Tokens

    //variables
    uint256 public totalAllocatedTokens;                         //variable to keep track of funds allocated
    uint256 public tokensAllocatedToCrowdFund;                   //funds allocated to crowdfund

    //addresses
    address public founderMultiSigAddress;                      //Multi sign address of founders which hold
    address public crowdFundAddress;                            //Address of crowdfund contract

    //events
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
    
    //modifierss

    modifier nonZeroAddress(address _to){
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders(){
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    modifier onlyCrowdfund(){
        require(msg.sender == crowdFundAddress);
        _;
    }

    //creation of token contract
    function HRAToken(address _crowdFundAddress, address _founderMultiSigAddress) {
        crowdFundAddress = _crowdFundAddress;
        founderMultiSigAddress = _founderMultiSigAddress;

        // Assigned balances to founder 
        balances[crowdFundAddress] = initialSupply;
    }

    //function to keep track of the total token allocation
    function changeTotalSupply(uint256 _amount) onlyCrowdfund {
        totalAllocatedTokens += _amount;
    }

    //function to change founder Multisig wallet address
    function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
        founderMultiSigAddress = _newFounderMultiSigAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

}