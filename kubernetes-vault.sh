vault status

kubectl create ns $NAME_SPACE
kubectl config set-context --current --namespace=$NAME_SPACE

cat <<EOF | kubectl create -f -
kind: ServiceAccount
apiVersion: v1
metadata:
  name: $SERVICE_ACCOUNT
  namespace: $NAME_SPACE

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $SERVICE_ACCOUNT
  namespace: $NAME_SPACE
rules:
  - apiGroups:
      - ""
    resources:
      - secrets
    verbs:
      - "*"

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $SERVICE_ACCOUNT
  namespace: $NAME_SPACE
roleRef:
  kind: Role
  name: $SERVICE_ACCOUNT
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: ServiceAccount
    name: $SERVICE_ACCOUNT

---
# This binding allows the deployed Vault instance to authenticate clients
# through Kubernetes ServiceAccounts (if configured so).
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $SERVICE_ACCOUNT
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: $SERVICE_ACCOUNT
    namespace: $NAME_SPACE
EOF

vault auth enable -path=$CLUSTER_NAME kubernetes

kubectl describe serviceaccount $SERVICE_ACCOUNT
VAULT_SECRET_NAME=$(kubectl get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-sidecar-token-")).name')
echo $VAULT_SECRET_NAME
kubectl describe secret $VAULT_SECRET_NAME

TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)
KUBE_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')
echo $TOKEN_REVIEW_JWT $KUBE_CA_CERT $KUBE_HOST

## https://particule.io/en/blog/vault-1.21/
vault write auth/$CLUSTER_NAME/config \
  issuer="https://kubernetes.default.svc.cluster.local" \
  token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
  kubernetes_host="$KUBE_HOST" \
  kubernetes_ca_cert="$KUBE_CA_CERT" disable_iss_validation=true

vault policy write $POLICY - <<EOF
path "secret/data/projects/$GCP_PROJECT/$CLUSTER_NAME/*" {
  capabilities = ["read"]
}
EOF

vault write auth/$CLUSTER_NAME/role/$ROLE \
  bound_service_account_names=$SERVICE_ACCOUNT \
  bound_service_account_namespaces=$NAME_SPACE \
  policies=$POLICY \
  ttl=24h

## Testing Authentication
demo_secret_name="$(kubectl get serviceaccount $SERVICE_ACCOUNT -n $NAME_SPACE -o go-template='{{ (index .secrets 0).name }}')"
demo_account_token="$(kubectl get secret ${demo_secret_name} -n $NAME_SPACE -o go-template='{{ .data.token }}' | base64 --decode)"
echo $demo_secret_name $demo_account_token
vault write auth/$CLUSTER_NAME/login role=$ROLE jwt=$demo_account_token