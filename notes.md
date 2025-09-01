 ## 🔧 Challenge: Build a "TokenSale" Contract with Custom Modifiers

## 🎯 Goal:
Create a contract where users can buy tokens, but only if:
The sale is open.
They send enough ETH.
They don’t exceed a purchase limit per wallet.

## 🧱 Requirements:
 - startSale
 () and endSale() functions to toggle isSaleOpen.
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


## 🔑 Core Components

## Token Reference

The contract should integrate with the ERC20 (or ERC777/ERC1155) token contract being sold.

Usually requires an IERC20 public token;.

Sale Parameters

Price: How much 1 token costs in ETH or another payment token (e.g., uint256 public rate; // tokens per ETH).

Cap: Maximum tokens or funds to raise (hard cap).

Start & End Time: Time window for the sale.

Minimum Contribution: Smallest amount allowed per buyer.

Maximum Contribution: Largest amount per buyer (anti-whale).

Payment Handling

Accepts ETH (or stablecoins like USDC/DAI).

Tracks how much each participant contributed (mapping(address => uint256) contributions;).

Token Distribution

Immediate delivery: Tokens are transferred to the buyer on purchase.

Vesting/Lockup: Tokens are locked and claimable later.

Safe math to avoid overflows when calculating tokens.

Fund Management

Decide where raised funds go:

Forward directly to the project wallet (payable wallet).

Hold in the contract until sale ends, then withdraw.

Access Control

Owner/Admin: Can configure parameters, pause/resume sale, withdraw funds.

Use Ownable from OpenZeppelin.

Security

NonReentrant: Prevent reentrancy on token purchase/withdraw.

Require statements: Enforce cap, time window, and valid ETH amount.

Whitelist (optional): Restrict who can participate (KYC/AML).

🛠️ Optional but Common Features

Refund Mechanism

If soft cap isn’t reached, contributors can withdraw ETH back.

Tiered Pricing

Early buyers get cheaper tokens, price increases over time.

Pause/Unpause

Admin can halt the sale in emergencies.

Stablecoin Payments

Accept USDC/DAI in addition to ETH.

Events

Emit logs for transparency:

event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);


Finalization

After sale ends:

Unsold tokens can be burned, sent to treasury, or reserved.

✅ Minimal Pseudocode Flow
function buyTokens() payable {
    require(saleIsActive && now within timeRange);
    require(contribution + msg.value <= maxContribution);

    tokensToBuy = msg.value * rate;
    require(tokensSold + tokensToBuy <= cap);

    contributions[msg.sender] += msg.value;
    tokensSold += tokensToBuy;

    transfer tokensTo buyer (or lock them for later);
    forward ETH to wallet (or store in contract);
}