
#!/bin/bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

SSH_USER="ubuntu"
CONTROL_KEY="$HOME/.ssh/gcp_key"

MACHINES=("machine-01" "machine-02" "machine-03")

declare -A PUBLIC_IPS
declare -A PRIVATE_IPS
declare -A PUBLIC_KEYS

SSH_OPTIONS=(
    -i "$CONTROL_KEY"
    -o IdentitiesOnly=yes
    -o BatchMode=yes
    -o ConnectTimeout=10
    -o StrictHostKeyChecking=accept-new
)

echo "======================================"
echo "       GCP SSH AUTOMATION SETUP"
echo "======================================"

# 1. Check prerequisites

echo "[1/7] Checking prerequisites..."

if ! command -v terraform >/dev/null; then
    echo "ERROR: Terraform is not installed."
    exit 1
fi

if [[ ! -f "$CONTROL_KEY" ]]; then
    echo "ERROR: Control Node SSH key not found."
    exit 1
fi

chmod 700 "$HOME/.ssh"
chmod 600 "$CONTROL_KEY"

if ! command -v jq >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y jq
fi

# 2. Get Terraform outputs

echo "[2/7] Reading Terraform outputs..."

PUBLIC_JSON=$(terraform output -json public_ips)
PRIVATE_JSON=$(terraform output -json private_ips)

for machine in "${MACHINES[@]}"; do

    PUBLIC_IPS[$machine]=$(echo "$PUBLIC_JSON" |
        jq -er --arg name "$machine" '.[$name]')

    PRIVATE_IPS[$machine]=$(echo "$PRIVATE_JSON" |
        jq -er --arg name "$machine" '.[$name]')

    echo "$machine"
    echo "  Public IP : ${PUBLIC_IPS[$machine]}"
    echo "  Private IP: ${PRIVATE_IPS[$machine]}"

done

# Remote SSH helper

remote() {
    local machine="$1"
    shift

    ssh "${SSH_OPTIONS[@]}" \
        "$SSH_USER@${PUBLIC_IPS[$machine]}" "$@"
}

# 3. Check VM connections

echo "[3/7] Checking VM connections..."

for machine in "${MACHINES[@]}"; do

    remote "$machine" "hostname"

    echo "Control Node -> $machine: SUCCESS"

done

# 4. Generate SSH keys on each VM

echo "[4/7] Generating SSH keys..."

for machine in "${MACHINES[@]}"; do

    remote "$machine" '
        set -e

        mkdir -p ~/.ssh
        chmod 700 ~/.ssh

        if [ ! -f ~/.ssh/id_ed25519 ]; then

            ssh-keygen -t ed25519 \
                -f ~/.ssh/id_ed25519 \
                -N "" \
                -C "$(hostname)"

        fi

        if [ ! -f ~/.ssh/id_ed25519.pub ]; then

            ssh-keygen -y -f ~/.ssh/id_ed25519 \
                > ~/.ssh/id_ed25519.pub

        fi

        chmod 600 ~/.ssh/id_ed25519
        chmod 644 ~/.ssh/id_ed25519.pub
    '

    PUBLIC_KEYS[$machine]=$(remote "$machine" \
        "cat ~/.ssh/id_ed25519.pub")

    echo "$machine: SSH key ready"

done

# 5. Exchange public keys between VMs

echo "[5/7] Exchanging public keys..."

for target in "${MACHINES[@]}"; do

    for source in "${MACHINES[@]}"; do

        if [[ "$source" == "$target" ]]; then
            continue
        fi

        printf '%s\n' "${PUBLIC_KEYS[$source]}" |
            remote "$target" '
                set -e

                mkdir -p ~/.ssh
                chmod 700 ~/.ssh

                touch ~/.ssh/authorized_keys
                chmod 600 ~/.ssh/authorized_keys

                while IFS= read -r key; do

                    if ! grep -qxF -- "$key" \
                        ~/.ssh/authorized_keys; then

                        printf "%s\n" "$key" \
                            >> ~/.ssh/authorized_keys

                    fi

                done
            '

        echo "$source -> $target: Key configured"

    done

done

# 6. Configure SSH aliases

echo "[6/7] Configuring SSH aliases..."

generate_config() {

    local ip_type="$1"

    for machine in "${MACHINES[@]}"; do

        local alias="${machine//-/}"
        local ip
        local identity

        if [[ "$ip_type" == "public" ]]; then

            ip="${PUBLIC_IPS[$machine]}"
            identity="~/.ssh/gcp_key"

        else

            ip="${PRIVATE_IPS[$machine]}"
            identity="~/.ssh/id_ed25519"

        fi

        cat <<EOF
Host $alias
    HostName $ip
    User $SSH_USER
    IdentityFile $identity
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ConnectTimeout 10

EOF

    done
}

# Configure Control Node using public IPs

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

generate_config public > "$HOME/.ssh/gcp-machines.conf"

chmod 600 "$HOME/.ssh/gcp-machines.conf"

touch "$HOME/.ssh/config"

if ! grep -qxF "Include ~/.ssh/gcp-machines.conf" \
    "$HOME/.ssh/config"; then

    {
        echo "Include ~/.ssh/gcp-machines.conf"
        echo
        cat "$HOME/.ssh/config"

    } > "$HOME/.ssh/config.tmp"

    mv "$HOME/.ssh/config.tmp" "$HOME/.ssh/config"

fi

chmod 600 "$HOME/.ssh/config"

# Configure GCP VMs using private IPs

for machine in "${MACHINES[@]}"; do

    generate_config private |
        remote "$machine" '
            set -e

            mkdir -p ~/.ssh
            chmod 700 ~/.ssh

            cat > ~/.ssh/gcp-machines.conf

            chmod 600 ~/.ssh/gcp-machines.conf

            touch ~/.ssh/config

            if ! grep -qxF "Include ~/.ssh/gcp-machines.conf" \
                ~/.ssh/config; then

                {
                    echo "Include ~/.ssh/gcp-machines.conf"
                    echo
                    cat ~/.ssh/config

                } > ~/.ssh/config.tmp

                mv ~/.ssh/config.tmp ~/.ssh/config

            fi

            chmod 600 ~/.ssh/config
        '

    echo "$machine: SSH aliases configured"

done

# 7. Test all SSH connections

echo "[7/7] Testing all SSH connections..."

FAILED=0

# Test Control Node -> All VMs

for target in "${MACHINES[@]}"; do

    alias="${target//-/}"

    if ssh -o BatchMode=yes "$alias" hostname; then

        echo "Control Node -> $target: SUCCESS"

    else

        echo "Control Node -> $target: FAILED"
        FAILED=$((FAILED + 1))

    fi

done

# Test VM -> VM connections

for source in "${MACHINES[@]}"; do

    for target in "${MACHINES[@]}"; do

        if [[ "$source" == "$target" ]]; then
            continue
        fi

        alias="${target//-/}"

        if remote "$source" \
            "ssh -o BatchMode=yes $alias hostname"; then

            echo "$source -> $target: SUCCESS"

        else

            echo "$source -> $target: FAILED"
            FAILED=$((FAILED + 1))

        fi

    done

done

echo "======================================"

if [[ "$FAILED" -eq 0 ]]; then

    echo "SSH AUTOMATION COMPLETED SUCCESSFULLY"

else

    echo "SSH SETUP COMPLETED WITH $FAILED FAILED TESTS"
    exit 1

fi

echo "======================================"
echo "Available SSH commands:"
echo "ssh machine01"
echo "ssh machine02"
echo "ssh machine03"
echo "======================================"
