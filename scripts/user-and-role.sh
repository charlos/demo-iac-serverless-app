#!/bin/bash
set -e

ACCOUNT_ID=123456789012
USER_NAME="demo-pipeline"
ROLE_NAME="demo-terraform"

# Obtener ID de cuenta AWS
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

echo "- Creando según configuración:"
echo "  - Rol: ${ROLE_NAME}"
echo "  - Usuario: ${USER_NAME}"
echo "  - Cuenta: ${ACCOUNT_ID}"
echo ""

# ======== Crear usuario IAM ========
echo "➡️ Creando usuario ${USER_NAME} (solo acceso programático)..."

if aws iam get-user --user-name "${USER_NAME}" &>/dev/null; then
  echo "⚠️ Usuario ${USER_NAME} ya existe, saltando creación."
else
  aws iam create-user --user-name "${USER_NAME}"
fi

# Crear Access Key
USER_ACCESS_KEYS=$(aws iam create-access-key --user-name "${USER_NAME}")
USER_AWS_ACCESS_KEY_ID=$(echo "$USER_ACCESS_KEYS" | jq -r '.AccessKey.AccessKeyId')
USER_AWS_SECRET_ACCESS_KEY=$(echo "$USER_ACCESS_KEYS" | jq -r '.AccessKey.SecretAccessKey')

echo "- Usuario ${USER_NAME} creado con claves programáticas."

# ======== Crear rol IAM ========
echo "➡️ Creando rol ${ROLE_NAME} confiando en ${USER_NAME}..."

cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::${ACCOUNT_ID}:root" },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalArn": "arn:aws:iam::${ACCOUNT_ID}:user/${USER_NAME}"
        }
      }
    }
  ]
}
EOF

if aws iam get-role --role-name "${ROLE_NAME}" &>/dev/null; then
  echo "⚠️ Rol ${ROLE_NAME} ya existe, actualizando política de confianza..."
  aws iam update-assume-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-document file://trust-policy.json
else
  aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document file://trust-policy.json
fi

# Adjuntar permisos administrativos
aws iam attach-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "- Rol ${ROLE_NAME} con permisos AdministratorAccess."

# ======== Permitir que el usuario asuma el rol ========
echo "➡️ Creando política inline para ${USER_NAME}..."

cat > assume-role-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole",
        "iam:GetRole",
        "iam:ListRoles"
      ],
      "Resource": "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
    }
  ]
}
EOF

aws iam put-user-policy \
  --user-name "${USER_NAME}" \
  --policy-name "Assume${ROLE_NAME}Role" \
  --policy-document file://assume-role-policy.json

echo "- ${USER_NAME} puede asumir el rol ${ROLE_NAME}."

# ======== Mostrar resultado ========
echo ""
echo "------------------------------------------"
echo "- Usuario IAM '${USER_NAME}' creado exitosamente"
echo "- Credenciales AWS CLI:"
echo ""
echo "AWS_ACCESS_KEY_ID=${USER_AWS_ACCESS_KEY_ID}"
echo "AWS_SECRET_ACCESS_KEY=${USER_AWS_SECRET_ACCESS_KEY}"
echo ""
echo "Asumir el rol con:"
echo "aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} --role-session-name ${ROLE_NAME}-session"
echo "------------------------------------------"
