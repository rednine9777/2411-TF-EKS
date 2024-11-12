#!/bin/bash

# 시스템 패키지 업데이트
sudo yum update -y

# Git 설치
sudo yum install -y git

# Docker 설치
sudo amazon-linux-extras install docker -y

# Docker 서비스 시작 및 부팅 시 자동 시작 설정
sudo systemctl start docker
sudo systemctl enable docker

# 현재 사용자를 Docker 그룹에 추가하여 sudo 없이 Docker 명령어 사용 가능하게 설정
sudo usermod -aG docker $USER

# 변경 사항 적용을 위해 현재 셸 재시작
newgrp docker

# 홈 디렉토리로 이동
cd ~

# 2048 게임 소스 클론
git clone https://github.com/gabrielecirulli/2048

# 2048 디렉토리로 이동
cd 2048

# Dockerfile 생성
cat <<EOF > Dockerfile
FROM nginx:latest
COPY . /usr/share/nginx/html
EXPOSE 80
EOF

# Docker 이미지 빌드
docker build -t web2048 .

# Docker 컨테이너 실행
docker run --name web2048 -dp 80:80 web2048

# kubectl 설치
sudo curl -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.4/2023-05-11/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl

# kubectl 버전 확인
kubectl version --client=true --short=true

# eksctl 설치
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_\$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin

# eksctl 버전 확인
eksctl version

# 현재 리전의 정보를 환경변수에 저장
export AWS_REGION=\$(curl --silent http://169.254.169.254/latest/meta-data/placement/region) && echo \$AWS_REGION

# EKS 클러스터 생성 (약 15분 소요)
eksctl create cluster --name myeks --version 1.26 --region \${AWS_REGION}

# 노드 리스트 확인
kubectl get nodes
