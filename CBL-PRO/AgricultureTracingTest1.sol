pragma solidity ^0.4.24;

pragma experimental ABIEncoderV2; //可以使用string[]

// import "./Table.sol";

contract AgricultureTracingTest1 {
    address private _owner;

    modifier onlyOwner {
        require(_owner == msg.sender, "Auth: only owner is authorized");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        create();
    }

    event createEvent(address owner, string tableName);
    event insertEvent(string tableName, string batchNUm, int256 c_type);

    // 创建农产品溯源表
    function create() private onlyOwner returns (int256) {
        TableFactory tf = TableFactory(0x1001);
        int256 count = tf.createTable(
            "t_agriculture_tracing",
            "batch_num",
            "json_data, type"
        );
        emit createEvent(msg.sender, "t_agriculture_tracing");
        return count;
    }

    /*
    描述 ： 插入生产信息
    参数 ： 
            batch_num ： 批次号
            json_data ： json格式数据
    返回值 ：
            0 ： 失败，该批次已有生产信息
            1 ： 成功
    */
    function insertProduct(string memory batch_num, string memory json_data)
        public
        onlyOwner
        returns (int256)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_agriculture_tracing");
        int256 product_type = 1;
        // 插入生产信息
        Entry entry = table.newEntry();
        entry.set("batch_num", batch_num);
        entry.set("json_data", json_data);
        entry.set("type", product_type);
        int256 count = table.insert(batch_num, entry);
        emit insertEvent(batch_num, json_data, product_type);
        return count;
    }

    /*
    描述 ： 插入流转信息
    参数 ： 
            batch_num ： 批次号
            qrcode :  二维码
            json_data ： json格式数据
    返回值 ：
            0 :  失败，该批次尚无生产信息
            1 ： 成功
    */
    function insertTransfer(string memory batch_num, string memory json_data)
        public
        onlyOwner
        returns (int256)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_agriculture_tracing");
        int256 product_type = 1;
        int256 transfer_type = 2;
        Condition condition = table.newCondition();
        condition.EQ("batch_num", batch_num);
        condition.EQ("type", product_type);
        Entries entries = table.select(batch_num, condition);
        // 该批次尚无生产信息
        if (entries.size() == 0) {
            return 0;
        }
        // 插入流转信息
        else {
            Entry entry = table.newEntry();
            entry.set("batch_num", batch_num);
            entry.set("json_data", json_data);
            entry.set("type", transfer_type);
            int256 count = table.insert(batch_num, entry);

            emit insertEvent(batch_num, json_data, transfer_type);
            return count;
        }
    }

    /*
    描述 ： 通过批次号查询
    参数 ： 
            batch_num ： 批次号
            c_type : 类型（1-生产+流转；2-生产；3-流转）
    返回值 ： 
            json格式字符串数据，error-批次号不存在
    */
    function selectByBatch(string memory batch_num, int256 c_type)
        public
        view
        returns (string[])
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_agriculture_tracing");
        Condition condition = table.newCondition();
        condition.EQ("batch_num", batch_num);
        if (c_type != 1) {
            // 只查生产信息
            if (c_type == 2) {
                condition.EQ("type", 1);
            }
            // 只查流转信息
            if (c_type == 3) {
                condition.EQ("type", 2);
            }
        }
        Entries entries = table.select(batch_num, condition);
        // 初始化数组大小
        string[] memory result_data = new string[](uint256(entries.size()));
        // 给数组赋值
        for (int256 i = 0; i < entries.size(); ++i) {
            Entry entry = entries.get(i);
            // 添加数组元素
            result_data[uint256(i)] = entry.getString("json_data");
        }
        return (result_data);
    }
}

// table.sol，因为在webase-front的IDE中无法直接引用，所以将源码放到代码文件中

contract TableFactory {
    function openTable(string memory) public view returns (Table) {} //open table

    function createTable(
        string memory,
        string memory,
        string memory
    ) public returns (int256) {} //create table
}

//select condition

contract Condition {
    function EQ(string memory, int256) public {}

    function EQ(string memory, string memory) public {}

    function NE(string memory, int256) public {}

    function NE(string memory, string memory) public {}

    function GT(string memory, int256) public {}

    function GE(string memory, int256) public {}

    function LT(string memory, int256) public {}

    function LE(string memory, int256) public {}

    function limit(int256) public {}

    function limit(int256, int256) public {}
}

//one record

contract Entry {
    function getInt(string memory) public view returns (int256) {}

    function getUInt(string memory) public view returns (int256) {}

    function getAddress(string memory) public view returns (address) {}

    function getBytes64(string memory)
        public
        view
        returns (bytes1[64] memory)
    {}

    function getBytes32(string memory) public view returns (bytes32) {}

    function getString(string memory) public view returns (string memory) {}

    function set(string memory, int256) public {}

    function set(string memory, uint256) public {}

    function set(string memory, string memory) public {}

    function set(string memory, address) public {}
}

//record sets

contract Entries {
    function get(int256) public view returns (Entry) {}

    function size() public view returns (int256) {}
}

//Table main contract

contract Table {
    function select(string memory, Condition) public view returns (Entries) {}

    function insert(string memory, Entry) public returns (int256) {}

    function update(
        string memory,
        Entry,
        Condition
    ) public returns (int256) {}

    function remove(string memory, Condition) public returns (int256) {}

    function newEntry() public view returns (Entry) {}

    function newCondition() public view returns (Condition) {}
}

contract KVTableFactory {
    function openTable(string memory) public view returns (KVTable) {}

    function createTable(
        string memory,
        string memory,
        string memory
    ) public returns (int256) {}
}

//KVTable per permiary key has only one Entry

contract KVTable {
    function get(string memory) public view returns (bool, Entry) {}

    function set(string memory, Entry) public returns (int256) {}

    function newEntry() public view returns (Entry) {}
}
