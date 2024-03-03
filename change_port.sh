read -p "Enter port number prefix (max 2 digits, not exceeding 50): " port_side
while [[ "$port_side" =~ [^0-9] || ${#port_side} -gt 2 || $port_side -gt 50 ]]; do
    read -p "Invalid input, enter port number prefix (max 2 digits, not exceeding 50): " port_side
done
sided config node tcp://localhost:${port_side}657
sed -i.bak -e "s%:1317%:${port_side}317%g; s%:8080%:${port_side}080%g; s%:9090%:${port_side}090%g; s%:9091%:${port_side}091%g; s%:8545%:${port_side}545%g; s%:8546%:${port_side}546%g; s%:6065%:${port_side}065%g" $HOME/.side/config/app.toml
sed -i.bak -e "s%:26658%:${port_side}658%g; s%:26657%:${port_side}657%g; s%:6060%:${port_side}060%g; s%:26656%:${port_side}656%g; s%:26660%:${port_side}660%g" $HOME/.side/config/config.toml
sudo systemctl daemon-reload
sudo systemctl restart sided