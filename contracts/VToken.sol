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

    function mintFor(address recipient, uint256 amount) external onlyOwner {
       balanceOf[recipient] = balanceOf[recipient].add(amount);
       totalSupply = totalSupply.add(amount);
    }

    function burn(uint256 amount) external {
       balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
       totalSupply = totalSupply.sub(amount);
    }
}
