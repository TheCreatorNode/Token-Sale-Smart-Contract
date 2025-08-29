 ## 🔧 Challenge: Build a "TokenSale" Contract with Custom Modifiers

## 🎯 Goal:
Create a contract where users can buy tokens, but only if:
The sale is open.
They send enough ETH.
They don’t exceed a purchase limit per wallet.

## 🧱 Requirements:
 - startSale() and endSale() functions to toggle isSaleOpen.
- A buyTokens() function that: Uses a costs modifier to check for minimum ETH sent (e.g. 0.01 ether per token)
Uses onlyWhileOpen to allow purchase only when the sale is active
Uses withinLimit to restrict max 100 tokens per address

## 🛠 You need to:
Write 3 modifiers:

onlyWhileOpen()
costs()
withinLimit()

Use mappings to track how many tokens each address bought:
solidity
Copy
Edit
mapping(address => uint) public tokensBought;

🧪 Bonus Challenge:
Add a noReentrancy modifier.

Make the token purchase call payable.

Emit a TokensPurchased(address buyer, uint amount) event.