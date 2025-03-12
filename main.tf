name: Deploy DB

on:
  workflow_dispatch: {}

jobs:
  deploy-db:
    runs-on: ubuntu-latest

    steps:
      # 1. Fazer checkout do repositório
      - name: Check out repository
        uses: actions/checkout@v3

      # 2. (Debug) Listar arquivos para verificar se main.tf e init.sql estão na raiz
      - name: Debug - list files
        run: |
          echo "### Current directory"
          pwd
          echo "### Files in the repo"
          ls -l

      # 3. Instalar Terraform
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.4.6'

      # 4. Terraform Init
      - name: Terraform Init
        run: terraform init
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION:    'us-east-1'

      # 5. Terraform Plan
      - name: Terraform Plan
        run: |
          terraform plan \
            -var="db_name=${{ secrets.RDS_DATABASE }}" \
            -var="db_username=${{ secrets.RDS_USERNAME }}" \
            -var="db_password=${{ secrets.RDS_PASSWORD }}"
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION:    'us-east-1'

      # 6. Terraform Apply
      - name: Terraform Apply
        run: |
          terraform apply -auto-approve \
            -var="db_name=${{ secrets.RDS_DATABASE }}" \
            -var="db_username=${{ secrets.RDS_USERNAME }}" \
            -var="db_password=${{ secrets.RDS_PASSWORD }}"
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION:    'us-east-1'

      # 7. Instalar/Atualizar AWS CLI via binário oficial
      - name: Install/Update AWS CLI
        run: |
          curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          sudo ./aws/install --update

      # 8. Obter endpoint do RDS via AWS CLI
      - name: Retrieve Endpoint using AWS CLI
        id: get_endpoint_awscli
        run: |
          RDS_ENDPOINT=$(aws rds describe-db-instances \
            --db-instance-identifier fastfood-db \
            --query 'DBInstances[0].Endpoint.Address' \
            --output text)
          echo "DB_ENDPOINT=$RDS_ENDPOINT" >> $GITHUB_ENV
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION:    'us-east-1'

      # 9. (Opcional) Aguardar alguns segundos para garantir que o DB esteja respondendo
      - name: Wait for RDS
        run: sleep 30

      # 10. Instalar PostgreSQL client
      - name: Install PostgreSQL client
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      # 11. Executar init.sql
      - name: Execute init.sql
        run: |
          psql "postgres://${{ secrets.RDS_USERNAME }}:${{ secrets.RDS_PASSWORD }}@${{ env.DB_ENDPOINT }}/${{ secrets.RDS_DATABASE }}" -f init.sql
