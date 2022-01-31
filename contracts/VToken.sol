pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VToken is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;

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
}
