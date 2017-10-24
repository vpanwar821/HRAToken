pragma solidity ^0.4.15;

import './HRAToken.sol';
import './lib/safeMath.sol';

contract HRACrowdfund {
    
    using SafeMath for uint256;

    HRAToken public token;
    
    address public founderMulSigAddress;
    uint256 public exchangeRate;
    uint256 public ethRaised;
    bool private tokenDeployed = false;
    uint256 public tokenSold;
    uint256 public manualTransferToken;
    uint256 public tokenDistributeInDividend;
    uint8 internal EXISTS = 1;
    uint8 internal NEW = 0;

    address[] public investors;

    mapping (address => uint8) internal previousInvestor;

    event ChangeFounderMulSigAddress(address indexed _newFounderMulSigAddress , uint256 _timestamp);
    event ChangeRateOfToken(uint256 _timestamp, uint256 _newRate);
    event TokenPurchase(address indexed _beneficiary, uint256 _value, uint256 _amount);
    event AdminTokenSent(address indexed _to, uint256 _value);
    event SendDividend(address indexed _to , uint256 _value, uint256 _timestamp);

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

    function HRACrowdfund(address _founderMulSigAddress) {
        founderMulSigAddress = _founderMulSigAddress;
        exchangeRate = 320;
    }
   
    function setToken(address _tokenAddress) nonZeroAddress(_tokenAddress) onlyfounder {
         require(tokenDeployed == false);
         token = HRAToken(_tokenAddress);
         tokenDeployed = true;
    }

    function changeExchangeRate(uint256 _rate) onlyfounder returns (bool) {
        if(_rate != 0){
            exchangeRate = _rate;
            ChangeRateOfToken(now,_rate);
            return true;
        }
        return false;
    }

    function ChangeFounderWalletAddress(address _newAddress) onlyfounder nonZeroAddress(_newAddress) {
         founderMulSigAddress = _newAddress;
         ChangeFounderMulSigAddress(founderMulSigAddress,now);
    }

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


    function sendToken (address _to, uint256 _value)
    onlyfounder 
    nonZeroAddress(_to) 
    isTokenDeployed
    returns (bool)
    {
        if (_value == 0)
            return false;

        require(checkExistence(_to));

        if (token.transfer(_to, _value)) {
            previousInvestor[_to] = EXISTS;
            manualTransferToken = manualTransferToken.add(_value);
            token.changeTotalSupply(_value); 
            AdminTokenSent(_to, _value);
            return true;
        }
        return false;
    }
    
    function checkExistence(address _beneficiary) internal returns (bool) {
         if (token.balanceOf(_beneficiary) == 0 && previousInvestor[_beneficiary] == NEW) {
            investors.push(_beneficiary);
        }
        return true;
    }

    function provideDividend(uint256 _dividend) 
    onlyfounder 
    isTokenDeployed
    {
        for (uint8 i = 0 ; i < investors.length ; i++) {
            uint256 _value = (token.balanceOf(investors[i])).div(_dividend);
            dividendTransfer(investors[i], _value);
        }
    }

    function dividendTransfer(address _to, uint256 _value) private {
        if (token.transfer(_to,_value)) {
            token.changeTotalSupply(_value);
            tokenDistributeInDividend = tokenDistributeInDividend.add(_value);
            SendDividend(_to,_value,now);
        }
    }

    function fundTransfer(uint256 _funds) private {
        founderMulSigAddress.transfer(_funds);
    }
    
    function () payable {
        buyTokens(msg.sender);
    }

}
