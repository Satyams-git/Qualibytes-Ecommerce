#!/bin/bash

# =============================================================
# QualiBytesShop - EC2 Bootstrap Script (user_data)
# Installs: Java 21, Jenkins, Docker, Trivy, AWS CLI, Helm, kubectl
# OS: Ubuntu 24.04 LTS
# Last Updated: June 2026
# =============================================================

set -e  # Exit on any error

# --- System Update ---
sudo apt update -y
sudo apt upgrade -y

# --- Java 21 Installation (Jenkins 2.479+ requires Java 21 minimum) ---
sudo apt install -y fontconfig openjdk-21-jre
sudo update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java

# --- Jenkins Installation ---
# Fetch GPG key from keyserver (jenkins.io key file method is unreliable)
sudo gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68
sudo gpg --export 7198F4B714ABFC68 | sudo tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null

# Add Jenkins stable repo
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

sudo systemctl start jenkins
sudo systemctl enable jenkins

# --- Docker Installation ---
sudo apt-get install -y docker.io

# Add current user and jenkins user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins

sudo systemctl restart docker
sudo systemctl restart jenkins

# --- Trivy Installation (Container Security Scanner) ---
sudo apt-get install -y wget apt-transport-https gnupg lsb-release snapd

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/trivy-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y trivy

# --- AWS CLI Installation ---
sudo snap install aws-cli --classic

# --- Helm Installation (Kubernetes Package Manager) ---
sudo snap install helm --classic

# --- kubectl Installation (Kubernetes CLI) ---
sudo snap install kubectl --classic

# --- Verification ---
echo "========================================="
echo "  Installation Complete! Verifying..."
echo "========================================="
echo "Java:    $(java -version 2>&1 | head -1)"
echo "Jenkins: $(dpkg -l jenkins | grep jenkins | awk '{print $3}')"
echo "Docker:  $(docker --version)"
echo "Trivy:   $(trivy --version 2>&1 | head -1)"
echo "AWS CLI: $(aws --version 2>&1)"
echo "Helm:    $(helm version --short 2>&1)"
echo "kubectl: $(kubectl version --client --short 2>&1)"
echo "========================================="
echo "  All tools installed successfully!"
echo "========================================="
