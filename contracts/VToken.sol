pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VToken is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowanceBurn;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    constructor (string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        decimals = 18;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
       balanceOf[_to] = balanceOf[_to].add(_amount);
       totalSupply = totalSupply.add(_amount);
    }

    function burn(uint256 _amount) external {
       balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
       totalSupply = totalSupply.sub(_amount);
    }

    function burnFrom(address _to, uint256 _amount) external {
       require(allowanceBurn[_to][msg.sender] >= _amount, "Not allowed");
       balanceOf[_to] = balanceOf[_to].sub(_amount);
       totalSupply = totalSupply.sub(_amount);
    }

    function approveBurn(address _spender, uint256 _amount) external {
       allowanceBurn[msg.sender][_spender] = _amount;
    }
}
