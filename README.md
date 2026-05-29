# [AWS wireguard VPN terraform stack](https://github.com/TeemuKoivisto/aws-wireguard-vpn-terraform)

To run them, you need:

- [Terraform](https://www.terraform.io/) (`brew install terraform`)
- Wireguard (`brew install wireguard-tools`)
- AWS credentials

1. Create Wireguard conf eg. `cd /opt/homebrew/etc/wireguard && wg genkey | tee privatekey | wg pubkey > publickey`
2. From the repo root, create `wg0.conf` from the template here, substituting your generated PrivateKey: `sed "s|PrivateKey = .*|PrivateKey = $(cat /opt/homebrew/etc/wireguard/privatekey)|" wg0.conf > /opt/homebrew/etc/wireguard/wg0.conf && chmod 600 /opt/homebrew/etc/wireguard/wg0.conf`
3. Create S3 bucket in a region of your desire (eg. `aws s3 mb s3://my-bucket --region eu-central-1`)
4. Copy env `cp .env-example .env`
5. In `.env` change:

- AWS credentials
- region (if not eu-central-1)
- ssh key name
- your ip
- client publickey (from `/opt/homebrew/etc/wireguard`)

6. Add the S3 bucket to `backend.conf`
7. Initialize Terraform: `./ex.sh tf init -backend-config=backend.conf`
8. Apply the stacks: `./ex.sh tf apply`
9. Copy the publickey & ip to your wg0.conf: `./ex.sh sync`
10. NOTE: If sync fails to copy the file, you might have to ssh manually: `./ex.sh ssh <ip>`
11. Start Wireguard: `./ex.sh wup`
12. Stop Wireguard: `./ex.sh wdown`
13. When you no longer need the VPN, run: `./ex.sh tf destroy`

## References

https://blog.scottlowe.org/2021/06/28/using-wireguard-on-mac-via-cli/

https://blog.scottlowe.org/2021/02/22/setting-up-wireguard-for-aws-vpc-access/
