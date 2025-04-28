import React, { useState, useEffect } from "react";
import { ethers } from "ethers";
import "./App.css";

// Replace this with your deployed contract address
const CONTRACT_ADDRESS = "0x420079D9bf9c5D3c7aA31cD2e93c833E16C50A31";

// Replace with your contract ABI
const CONTRACT_ABI = [
  "function submitLabel(uint256 dataId, string memory label) public",
  "function getBalance(address user) public view returns (uint256)",
  "function withdrawRewards() public",
  "function transferTokens(address to, uint256 amount) public",
  "function mintTokens(address to, uint256 amount) public",
  "function pauseContract() public",
  "function unpauseContract() public",
  "function owner() public view returns (address)",
  "function paused() public view returns (bool)"
];

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState(null);
  const [owner, setOwner] = useState(null);
  const [balance, setBalance] = useState(0);
  const [paused, setPaused] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");

  const [dataId, setDataId] = useState("");
  const [label, setLabel] = useState("");
  const [recipient, setRecipient] = useState("");
  const [transferAmount, setTransferAmount] = useState("");

  useEffect(() => {
    const init = async () => {
      if (window.ethereum) {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
        const accounts = await provider.send("eth_requestAccounts", []);

        setProvider(provider);
        setSigner(signer);
        setContract(contract);
        setAccount(accounts[0]);

        const ownerAddress = await contract.owner();
        setOwner(ownerAddress);

        const pausedState = await contract.paused();
        setPaused(pausedState);

        fetchBalance(contract, accounts[0]);
      } else {
        alert("Please install MetaMask!");
      }
    };

    init();
  }, []);

  const fetchBalance = async (contractInstance, userAddress) => {
    const bal = await contractInstance.getBalance(userAddress);
    setBalance(ethers.BigNumber.from(bal).toString());
  };

  const handleSubmit = async (callback) => {
    try {
      setLoading(true);
      setMessage("Waiting for confirmation...");
      const tx = await callback();
      await tx.wait();
      setMessage("Transaction successful!");
      fetchBalance(contract, account);
    } catch (error) {
      console.error(error);
      setMessage(`Error: ${error.reason || error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmitLabel = () => {
    handleSubmit(() => contract.submitLabel(dataId, label));
  };

  const handleWithdraw = () => {
    handleSubmit(() => contract.withdrawRewards());
  };

  const handleTransfer = () => {
    handleSubmit(() =>
      contract.transferTokens(recipient, ethers.BigNumber.from(transferAmount))
    );
  };

  const handlePause = () => {
    handleSubmit(() => contract.pauseContract());
  };

  const handleUnpause = () => {
    handleSubmit(() => contract.unpauseContract());
  };

  return (
    <div className="App">
      <h1>📦 Data Labeling Incentives</h1>

      <div className="card">
        <p><strong>Connected Wallet:</strong> {account}</p>
        <p><strong>Token Balance:</strong> {balance}</p>
        <p><strong>Contract Paused:</strong> {paused ? "Yes" : "No"}</p>
        <button onClick={() => fetchBalance(contract, account)}>🔄 Refresh Balance</button>
      </div>

      <hr />

      <div className="card">
        <h2>🚀 Submit a Label</h2>
        <input
          type="number"
          placeholder="Data ID"
          value={dataId}
          onChange={(e) => setDataId(e.target.value)}
        />
        <input
          type="text"
          placeholder="Label"
          value={label}
          onChange={(e) => setLabel(e.target.value)}
        />
        <button onClick={handleSubmitLabel} disabled={loading}>Submit Label</button>
      </div>

      <div className="card">
        <h2>💰 Withdraw Rewards</h2>
        <button onClick={handleWithdraw} disabled={loading}>Withdraw</button>
      </div>

      <div className="card">
        <h2>🔁 Transfer Tokens</h2>
        <input
          type="text"
          placeholder="Recipient Address"
          value={recipient}
          onChange={(e) => setRecipient(e.target.value)}
        />
        <input
          type="number"
          placeholder="Amount"
          value={transferAmount}
          onChange={(e) => setTransferAmount(e.target.value)}
        />
        <button onClick={handleTransfer} disabled={loading}>Transfer</button>
      </div>

      {account && account.toLowerCase() === owner?.toLowerCase() && (
        <>
          <hr />
          <div className="card admin">
            <h2>⚙️ Admin Controls</h2>
            <button onClick={handlePause} disabled={paused || loading}>Pause Contract</button>
            <button onClick={handleUnpause} disabled={!paused || loading}>Unpause Contract</button>
          </div>
        </>
      )}

      {loading && <p className="loading">Processing transaction...</p>}
      {message && <p className="message">{message}</p>}
    </div>
  );
}

export default App;

