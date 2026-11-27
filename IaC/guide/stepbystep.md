## In my case i use AWS EC2 machine as control node machine and use terraform to create GCP machine

## There are 4 main step to write this  

### 1. generate ssh key on your machine 
### 2. Authenticated with gcloud
### 3. write code in main.tf and output.tf
### 4. Write command to create , destroy machine 

## The purpose of each step

#### 1. SSH key on EC2: Lets EC2 (and Ansible) log in securely to the 3 GCP VMs without a password.
#### 2. gcloud: Logs in your Google account so Terraform has permission to create/delete GCP resources ( dont need JSON key ).


## Do it now 

### 1. Generate ssh key on your machine 
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keygen -t ed25519 -f ~/.ssh/gcp_key -N "" -C "your-ssh-key-name"
```

### 2. Authenticated with gcloud

#### 2.1 Start ADC login 
```bash
gcloud auth application-default login --no-browser
```

#### 2.2 Run the --remote-bootstrap command on Windows
```bash
gcloud auth application-default login --remote-bootstrap="https://accounts.google.com/..."
```

#### 2.2.1 command to install gcloud on window
```bash
winget install -e --id Google.CloudSDK
gcloud --version
```

##### Runs on your Windows 11 terminal (where gcloud is installed) and opens your browser so you can sign in with your Google account and click Allow.
##### Outputs a local callback URL (https://localhost:8085/?state=...&code=...) that carries your authorization result back to EC2.

#### 2.3 Save credentials on EC2 and set the quota project
```bash
gcloud auth application-default set-quota-project your-project-id
```

#### 3 just code for 2 file : main.tf and output.tf

#### 4. Command 

#####  Create 
```bash
terraform init && terraform apply -auto-approve
```

##### Destroy
```bash
terraform destroy -auto-approve
```

##### Stop 
```bash
gcloud compute instances stop machine-01-name machine-02-name machine-03-name --zone=asia-east1-a
```

##### Verify Google's load balancer sees the instance group:
```bash
gcloud compute backend-services get-health app-services-backend --global
```

