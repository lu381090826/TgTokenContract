pragma solidity ^0.4.21;

//import "./Console.sol";

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}
// token的 接受者 这里声明接口, 将会在我们的ABI里

//contract TgToken is Console {
contract TgToken {
    /*********Token的属性说明************/
    string public name = 'TANKE';
    string public symbol = 'TANKE';
    uint8  public decimals = 4;  // 18 是建议的默认值
    uint256  public totalSupply = 1500000000 * 10 ** uint256(decimals); // 总发行量
    uint256  public mineralReleased; // 已发放的矿
    uint public supplyTimestamp;

    //三个管理员地址
    address adminAddress;
    address adminAddress2;
    address adminAddress3;

    // 建立映射 地址对应了 uint' 便是他的余额
    mapping(address => uint256) public balanceOf;

    // 最后发放收益时间
    mapping(address => uint256) public lastProfitTime;

    // 地址对应余额
    mapping(address => mapping(address => uint256)) public allowance;

    // 事件，用来通知客户端Token交易发生
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 事件，用来通知客户端代币被消耗(这里就不是转移, 是token用了就没了)
    event Burn(address indexed from, uint256 value);

    // 这里是构造函数, 实例创建时候执行
    function TgToken() public {

        // 这里就比较重要, 这里相当于实现了, 把token 全部给合约的Creator
        balanceOf[msg.sender] = totalSupply;
        //        log("balanceOf[msg.sender]=", balanceOf[msg.sender]);

        //发行时间
        supplyTimestamp = block.timestamp;

        adminAddress = msg.sender;
    }

    //    function getBalance(address _from) public {
    //
    //        log('balance=', balanceOf[_from]);
    //    }


    // token的发送函数
    function _transfer(address _from, address _to, uint _value) internal {

        require(_to != 0x0);
        // 不是零地址
        require(balanceOf[_from] >= _value);
        // 有足够的余额来发送
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // 这里也有意思, 不能发送负数的值(hhhh)

        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // 这个是为了校验, 避免过程出错, 总量不变对吧?
        balanceOf[_from] -= _value;
        //发钱 不多说
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // 这里触发了转账的事件 , 见上event
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        // 判断总额是否一致, 避免过程出错
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
        // 这里已经储存了 合约创建者的信息, 这个函数是只能被合约创建者使用
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        // 这句很重要, 地址对应的合约地址(也就是token余额)
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        // 这里是可花费总量
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    // 正如其名, 这个是烧币(SB)的.. ,用于把创建者的 token 烧掉
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        // 必须要有这么多
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    // 这个是用户销毁token.....
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        // 一样要有这么多
        require(_value <= allowance[_from][msg.sender]);
        //
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }

    function profit(address _to) public {
        //        log('now', now);
        //        log('lastProfitTime[_to] ', lastProfitTime[_to]);

        //每天只允许一次
        require(now - lastProfitTime[_to] >= 60);

        //        不允许交易地址和管理员地址一样
        require(_to != adminAddress);
        require(_to != adminAddress2);
        require(_to != adminAddress3);

        //计算收益
        uint256 balance = balanceOf[_to];
        uint256 profit = (balance * 1314) / 10000000;
        //        log('profit', profit);

        //检查是否允许发放
        checkMineral(profit);

        lastProfitTime[_to] = now;

        mineralReleased += profit;

        //交易
        _transfer(adminAddress, _to, profit);
    }

    //检查矿是不是超出发行范围
    function checkMineral(uint256 currentValue){
        // 相差时间
        uint diffYear = (now - supplyTimestamp) / 1 years + 1;
        // 每年矿允许的投入量,总量的60.08%，共45年发放
        uint256 perYearMineral = (totalSupply * 6008) / 10000 / 45;
        // 当前允许的量
        uint256 supplyMineral = diffYear * perYearMineral;

        //        log('mineralReleased', mineralReleased);
        //        log('currentValue', currentValue);
        //        log('supplyMineral', supplyMineral);
        require(mineralReleased + currentValue <= supplyMineral);

    }

}