# Развертывание СУБД PaaS при помощи Terraform

1. Создание ресурсов vk-cloud
Для задания были созданы: сеть, роутер, подсеть, инстанс базы данных с пользователем, виртуальная машина, с помощью которой происходило подключение к базе данных.

## 🚀 Быстрый старт

### 1. Клонирование репозитория

```bash
git clone https://github.com/somebodyaroundthere/db__vkcloud_terraform.git
cd db_vkcloud_terraform
```

### 2. Настройка переменных

измените переменные на те, которые вам нужны в файлах secret.tfvars, variables.tf и provider.tf

### 3. Инициализация и развертывание

```bash
# Инициализация Terraform
terraform init

# Просмотр плана развертывания
terraform plan -var-file="secret.tfvars"

# Развертывание инфраструктуры
terraform apply -var-file="secret.tfvars"
```
### 4. Подключение вм к базе данных

После успешного развертывания выполните:

```bash
sudo apt update
sudo apt install mysql-client-core-8
pip install mysql-connector-python dotenv
python3 script.py
```

## 📁 Структура проекта

```text
mysql-database-terraform/
├── main.tf                 # Основная конфигурация Terraform
├── variables.tf            # Определение переменных
├── vkcs_provider.tf        # Настройка провайдера VK Cloud
├── script.py               # Скрипт заполнения БД тестовыми данными
```
