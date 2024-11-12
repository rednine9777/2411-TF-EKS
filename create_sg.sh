#!/bin/bash

set -e

# 현재 AWS 리전 가져오기
CURRENT_REGION=$(aws configure get region)
echo "현재 설정된 AWS 리전: $CURRENT_REGION"

# AWS 계정 정보 가져오기
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
USER_ARN=$(aws sts get-caller-identity --query "Arn" --output text)
echo "AWS 계정 ID: $ACCOUNT_ID"
echo "AWS 사용자 ARN: $USER_ARN"

# AWS에 등록된 키 페어 목록 조회
KEY_PAIRS=($(aws ec2 describe-key-pairs --query "KeyPairs[*].KeyName" --output text))

if [ ${#KEY_PAIRS[@]} -eq 0 ]; then
  echo "AWS에 등록된 키 페어가 없습니다. 먼저 키 페어를 생성하세요."
  exit 1
fi

echo "사용 가능한 키 페어 목록:"
for i in "${!KEY_PAIRS[@]}"; do
  echo "$((i+1)). ${KEY_PAIRS[$i]}"
done

# 사용자로부터 키 페어 선택 받기
while true; do
  read -p "사용할 키 페어의 번호를 입력하세요: " KEY_INDEX
  if [[ "$KEY_INDEX" =~ ^[0-9]+$ ]]; then
    if (( KEY_INDEX >= 1 && KEY_INDEX <= ${#KEY_PAIRS[@]} )); then
      KEY_NAME="${KEY_PAIRS[$((KEY_INDEX-1))]}"
      echo "선택된 키 페어: $KEY_NAME"
      break
    else
      echo "유효한 번호를 입력하세요."
    fi
  else
    echo "유효한 번호를 입력하세요."
  fi
done

# 변수 설정
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
SECURITY_GROUP_NAME="my-security-group"
DESCRIPTION="My security group for EC2 instances"

# 보안 그룹 존재 여부 확인
EXISTING_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [ "$EXISTING_SG_ID" != "None" ] && [ -n "$EXISTING_SG_ID" ]; then
  echo "보안 그룹 '$SECURITY_GROUP_NAME'이(가) 이미 존재합니다."
  SG_ID=$EXISTING_SG_ID
else
  echo "보안 그룹 '$SECURITY_GROUP_NAME'이(가) 존재하지 않습니다. 새로 생성합니다."

  # 보안 그룹 생성
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "$DESCRIPTION" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)

  # 필요한 포트에 대한 인바운드 규칙 추가
  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp --port 22 --cidr 0.0.0.0/0
  # 추가 포트 규칙을 필요에 따라 추가하세요.

  echo "보안 그룹 생성 완료: $SG_ID"
fi

# Terraform 변수 파일에 키 페어 이름과 보안 그룹 ID 저장
cat <<EOF > terraform.tfvars
key_name           = "$KEY_NAME"
security_group_ids = ["$SG_ID"]
EOF

echo "terraform.tfvars 파일이 생성되었습니다."
echo "환경 설정이 완료되었습니다."
