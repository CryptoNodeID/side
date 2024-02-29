#!/bin/bash
GO_VERSION=$(go version 2>/dev/null | grep -oP 'go1\.22\.0')
if [ -z "$GO_VERSION" ]; then
    echo "Go is not installed or not version 1.22.0. Installing Go 1.22.0..."
    wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
    rm go1.22.0.linux-amd64.tar.gz
    if ! grep -q 'export GOPATH=' ~/.profile; then
        echo "export GOPATH=$HOME/go" >> ~/.profile
    fi
    if ! grep -q 'export PATH=.*$GOPATH/bin' ~/.profile; then
        echo "export PATH=$PATH:$GOPATH/bin" >> ~/.profile
    fi
    if ! grep -q 'export PATH=.*:/usr/local/go/bin' ~/.profile; then
        echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
    fi
    source ~/.profile
else
    echo "Go version 1.22.0 is already installed."
fi
sudo apt -qy install curl git jq lz4 build-essential unzip
rm -rf side
rm -rf $HOME/.side
git clone https://github.com/sideprotocol/side.git
cd side
git checkout v0.6.0
make install
if ! grep -q 'export SIDED_KEYRING_BACKEND=file' ~/.profile; then
    echo "export SIDED_KEYRING_BACKEND=file" >> ~/.profile
fi
source ~/.profile
sided version

mkdir -p $HOME/.side/cosmovisor/genesis/bin
mkdir -p $HOME/.side/cosmovisor/upgrades
cp $(which sided) $HOME/.side/cosmovisor/genesis/bin/

read -p "Enter validator key name: " VALIDATOR_KEY_NAME
if [ -z "$VALIDATOR_KEY_NAME" ]; then
    echo "Error: No validator key name provided."
    exit 1
fi
read -p "Do you want to recover wallet? [y/N]: " RECOVER
RECOVER=$(echo "$RECOVER" | tr '[:upper:]' '[:lower:]')
if [[ "$RECOVER" == "y" || "$RECOVER" == "yes" ]]; then
    sided keys add $VALIDATOR_KEY_NAME --recover
else
    sided keys add $VALIDATOR_KEY_NAME
fi
sided config chain-id side-testnet-2
sided init $VALIDATOR_KEY_NAME --chain-id=side-testnet-2
sided keys list
cp ../genesis.json $HOME/.side/config/genesis.json
cp ../addrbook.json $HOME/.side/config/addrbook.json
SEEDS="d9911bd0eef9029e8ce3263f61680ef4f71a87c4@13.230.121.124:26656,693bdfec73a81abddf6f758aa49321de48456a96@13.231.67.192:26656,2803ac0536102d14d1231ee2ba2401220e6e5161@188.40.66.173:26356,e1752865a89e132f7877bae1adae5b39b6f50a9f@88.198.27.51:61056,907b2fe62d44e4692befce1954280647e03cd9e0@136.243.75.46:26656,62b28c726dbcf81ff3227af3f3da1a9cec7b2898@65.21.113.10:60856,ddfe330127fcf8a6560fa24015c28c0a29148ada@65.108.143.210:45656,c3df7bc8a69f1d49186f53a51d799ebd2bf56952@65.108.206.118:46656,7898eaa74fd2bb62896e2ebc0bd56ffeb8a8d69c@178.63.100.17:26656,08f006100a637b2fea09eab6c124949fe437af3e@37.27.69.161:36656,6b812f26396666731dc4a4641d7e76aea7203a26@65.109.23.55:21306,afc5131919434d10d6912b1bb0048b887323b8f8@149.102.132.207:48656,dbe7d91d84f183cf26409cc42eb0c2a2c67de62a@167.235.178.134:26356,bbbf623474e377664673bde3256fc35a36ba0df1@side-testnet-peer.itrocket.net:45656,e085e0a039b339afd4bb013f4533a33b34a2308b@162.55.90.36:11356,74a4bfb27961536a99146b372a9f97e55716f946@116.202.174.53:36656,85a16af0aa674b9d1c17c3f2f3a83f28f468174d@167.235.242.236:26656,25346fac3e8403cf568ef71b153ce74ce0dd00bf@86.48.3.66:12556,45f2a80670a371eee2d15be7b13a607406b4b76f@23.88.70.109:11356,a70044f3fb90704ea5cc2fa21158462fe0a7c2f0@213.239.217.52:37656,5b21074ff383280912042e610c41c33526a0a616@185.119.116.238:26656,70e3c646a0bd0bce52714a5d6b27cf1604405167@167.86.67.112:26656,520f98acd537007a9a4e3c640873d6c0cb489af7@161.97.83.250:26656,71e1f43dd160bbc496d238d0367f610d2b2a9ac4@142.132.248.253:24656,027ef6300590b1ca3a2b92a274247e24537bd9c9@65.109.65.248:49656,5da25c70c00c80e68ba2595db7675263e1f8c85a@62.171.153.92:26656,21b783c07d7fe19b787ab49c68334eec88c52756@165.227.208.115:26656,d396afbf6aed52787fed1291e2d22d9342f8788a@58.186.204.19:26656"
sed -i 's/seeds = ""/seeds = "'"$SEEDS"'"/' $HOME/.side/config/config.toml
sed -i 's/minimum-gas-prices = "0stake"/minimum-gas-prices = "0.005uside"/' $HOME/.side/config/app.toml
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "10"|' \
  $HOME/.side/config/app.toml
indexer="null" && \
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.side/config/config.toml

# Helper scripts
cd "$(dirname "$0")"
rm -rf list_keys.sh check_balance.sh create_validator.sh unjail_validator.sh check_validator.sh start_side.sh check_log.sh
echo "sided keys list" > list_keys.sh && chmod +x list_keys.sh
echo "sided q bank balances $(sided keys show $VALIDATOR_KEY_NAME -a)" > check_balance.sh && chmod +x check_balance.sh
tee create_validator.sh > /dev/null <<EOF
#!/bin/bash
sided tx staking create-validator \
  --amount=1000000uside \
  --pubkey=\$(sided tendermint show-validator) \
  --moniker="$VALIDATOR_KEY_NAME" \
  --chain-id="side-testnet-2" \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --fees="200uside" \
  --from=$VALIDATOR_KEY_NAME
EOF
chmod +x create_validator.sh
tee unjail_validator.sh > /dev/null <<EOF
#!/bin/bash
sided tx slashing unjail \
 --from=$VALIDATOR_KEY_NAME \
 --chain-id="side-testnet-2"
EOF
chmod +x unjail_validator.sh
tee check_validator.sh > /dev/null <<EOF
#!/bin/bash
sided query tendermint-validator-set | grep "\$(sided tendermint show-address)"
EOF
chmod +x check_validator.sh
tee start_side.sh > /dev/null <<EOF
systemctl daemon-reload
systemctl enable sided
systemctl restart sided
EOF
chmod +x start_side.sh
tee check_log.sh > /dev/null <<EOF
journalctl -u sided -f
EOF
chmod +x check_log.sh

if ! command -v cosmovisor &> /dev/null; then
    wget https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv1.5.0/cosmovisor-v1.5.0-linux-amd64.tar.gz
    tar -xvzf cosmovisor-v1.5.0-linux-amd64.tar.gz
    rm cosmovisor-v1.5.0-linux-amd64.tar.gz
    sudo cp cosmovisor /usr/local/bin
fi
sudo tee /etc/systemd/system/sided.service > /dev/null <<EOF
[Unit]
Description=Side daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --x-crisis-skip-assert-invariants
Restart=always
RestartSec=3
LimitNOFILE=infinity

Environment="DAEMON_NAME=sided"
Environment="DAEMON_HOME=${HOME}/.side"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
read -p "Do you want to enable the sided service? (y/N): " ENABLE_SERVICE
if [[ "$ENABLE_SERVICE" =~ ^[Yy](es)?$ ]]; then
    sudo systemctl enable sided.service
else
    echo "Skipping enabling sided service."
fi