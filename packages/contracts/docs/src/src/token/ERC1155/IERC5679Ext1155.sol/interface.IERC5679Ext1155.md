# IERC5679Ext1155
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/token/ERC1155/IERC5679Ext1155.sol)

**Inherits:**
IERC1155


## Functions
### safeMint


```solidity
function safeMint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
```

### safeMintBatch


```solidity
function safeMintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata data)
    external;
```

### burn


```solidity
function burn(address _from, uint256 _id, uint256 _amount, bytes[] calldata _data) external;
```

### burnBatch


```solidity
function burnBatch(address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data)
    external;
```

