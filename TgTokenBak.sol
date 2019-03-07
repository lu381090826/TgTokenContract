pragma solidity ^0.4.21;

import "./Console.sol";

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}

contract TgToken is Console {
    string public name = 'TGCoin';
    string public symbol = 'TG';
    uint8  public decimals = 18;
    uint256  public totalSupply = 6800000000 * 10 ** uint256(decimals);
    uint256  public mineralReleased;
    uint256  public tradeReleased;
    uint public supplyTimestamp;
    address adminAddress;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) public lastProfitTime;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    function TgToken() public {

        balanceOf[msg.sender] = totalSupply;
        log("balanceOf[msg.sender]=", balanceOf[msg.sender]);

        supplyTimestamp = block.timestamp;

        adminAddress = msg.sender;
    }

    function getBalance(address _from) public {

        log('balance=', balanceOf[_from]);
    }

    function _transfer(address _from, address _to, uint _value) internal {

        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        //
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }

    function profit(address _to) public {

        require(msg.sender == adminAddress);

        require(now - lastProfitTime[_to] >= 60);

        checkMineral(currentValue);

        uint256 balance = balanceOf[_to];
        uint256 profit = (balance * 1314) / 10000000;

        lastProfitTime[_to] = now;

        mineralReleased += profit;

        _transfer(adminAddress, _to, profit);
    }

    //检查矿是不是超出发行范围
    function checkMineral(uint256 currentValue){
        uint diffYear = (now - supplyTimestamp) / 1 years + 1;
        uint256 perYearMineral = (totalSupply * 6008) / 10000 / 45;
        uint256 supplyMineral = diffYear * perYearMineral;

        require(mineralReleased + currentValue <= supplyMineral);
    }

    function checkTrade(uint256 currentValue){

        uint256 supplyTrade = (totalSupply * 1314) / 10000;

        require(tradeReleased + currentValue <= supplyTrade);

    }

    function buy(address _to, uint256 buyNum){

        checkTrade(buyNum);

        require(msg.sender == adminAddress);

        transfer(_to, buyNum);

    }

}