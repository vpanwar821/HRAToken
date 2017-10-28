pragma solidity ^0.4.15;

import './helpers/BasicToken.sol';
import './HRAToken.sol';

contract HRACrowdfund {
    
    using SafeMath for uint256;

    HRAToken public token;                                    // Token contract reference
    
    address public founderMulSigAddress;                      // Founders multisig address
    uint256 public exchangeRate;                              // Use to find token value against one ether
    uint256 public ethRaised;                                 // Counter to track the amount raised
    bool private tokenDeployed = false;                       // Flag to track the token deployment -- only can be set once
    uint256 public tokenSold;                                 // Counter to track the amount of token sold
    uint256 public manualTransferToken;                       // Counter to track the amount of manually tranfer token
    uint256 public tokenDistributeInDividend;                 // Counter to track the amount of token shared to investors
    uint8 internal EXISTS = 1;                                // Flag to track the existing investors
    uint8 internal NEW = 0;                                   // Flag to track the non existing investors

    address[] public investors;                               // Investors address 

    mapping (address => uint8) internal previousInvestor;
    //events
    event ChangeFounderMulSigAddress(address indexed _newFounderMulSigAddress , uint256 _timestamp);
    event ChangeRateOfToken(uint256 _timestamp, uint256 _newRate);
    event TokenPurchase(address indexed _beneficiary, uint256 _value, uint256 _amount);
    event AdminTokenSent(address indexed _to, uint256 _value);
    event SendDividend(address indexed _to , uint256 _value, uint256 _timestamp);
    
    //Modifiers
    modifier onlyfounder() {
        require(msg.sender == founderMulSigAddress);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderMulSigAddress);
        _;
    }

    modifier nonZeroEth() {
        require(msg.value != 0);
        _;
    }

    modifier isTokenDeployed() {
        require(tokenDeployed == true);
        _;
    }
    
    // Constructor to initialize the local variables 
    function HRACrowdfund(address _founderMulSigAddress) {
        founderMulSigAddress = _founderMulSigAddress;
        exchangeRate = 320;
    }
   
   // Attach the token contract, can only be done once   
    function setToken(address _tokenAddress) nonZeroAddress(_tokenAddress) onlyfounder {
         require(tokenDeployed == false);
         token = HRAToken(_tokenAddress);
         tokenDeployed = true;
    }
    
    // Function to change the exchange rate
    function changeExchangeRate(uint256 _rate) onlyfounder returns (bool) {
        if(_rate != 0){
            exchangeRate = _rate;
            ChangeRateOfToken(now,_rate);
            return true;
        }
        return false;
    }
    
    // Function to change the founders multisig address
    function ChangeFounderWalletAddress(address _newAddress) onlyfounder nonZeroAddress(_newAddress) {
         founderMulSigAddress = _newAddress;
         ChangeFounderMulSigAddress(founderMulSigAddress,now);
    }

    // Buy token function 
    function buyTokens (address _beneficiary)
    onlyPublic
    nonZeroAddress(_beneficiary)
    nonZeroEth
    isTokenDeployed
    payable
    public
    returns (bool)
    {
        uint256 amount = (msg.value.mul(exchangeRate)).div(10 ** 8);
       
        require(checkExistence(_beneficiary));

        if (token.transfer(_beneficiary, amount)) {
            fundTransfer(msg.value);
            previousInvestor[_beneficiary] = EXISTS;
            ethRaised = ethRaised.add(msg.value);
            tokenSold = tokenSold.add(amount);
            token.changeTotalSupply(amount); 
            TokenPurchase(_beneficiary, msg.value, amount);
            return true;
        }
        return false;
    }

    // Function to send token to user address
    function sendToken (address _to, uint256 _value)
    onlyfounder 
    nonZeroAddress(_to) 
    isTokenDeployed
    returns (bool)
    {
        if (_value == 0)
            return false;

        require(checkExistence(_to));
        
        uint256 _tokenAmount= _value * 10 ** uint256(token.decimals());

        if (token.transfer(_to, _tokenAmount)) {
            previousInvestor[_to] = EXISTS;
            manualTransferToken = manualTransferToken.add(_tokenAmount);
            token.changeTotalSupply(_tokenAmount); 
            AdminTokenSent(_to, _tokenAmount);
            return true;
        }
        return false;
    }
    
    // Function to check the existence of investor
    function checkExistence(address _beneficiary) internal returns (bool) {
         if (token.balanceOf(_beneficiary) == 0 && previousInvestor[_beneficiary] == NEW) {
            investors.push(_beneficiary);
        }
        return true;
    }
    
    // Function to calculate the percentage of token share to the existing investors
    function provideDividend(uint256 _dividend) 
    onlyfounder 
    isTokenDeployed
    {
        uint256 _supply = token.totalAllocatedTokens();
        uint256 _dividendValue = _dividend.mul(10 ** uint256(token.decimals()));
        for (uint8 i = 0 ; i < investors.length ; i++) {
            
            uint256 _value = ((token.balanceOf(investors[i])).mul(_dividendValue)).div(_supply);
            dividendTransfer(investors[i], _value);
        }
    }
    
    // Function to send the calculated tokens amount to the investor
    function dividendTransfer(address _to, uint256 _value) private {
        if (token.transfer(_to,_value)) {
            token.changeTotalSupply(_value);
            tokenDistributeInDividend = tokenDistributeInDividend.add(_value);
            SendDividend(_to,_value,now);
        }
    }
    
    // Function to transfer the funds to founders account
    function fundTransfer(uint256 _funds) private {
        founderMulSigAddress.transfer(_funds);
    }
    
    // Crowdfund entry
    // send ether to the contract address
    function () payable {
        buyTokens(msg.sender);
    }

}
