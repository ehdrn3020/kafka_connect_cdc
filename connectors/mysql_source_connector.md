### Mysql 설치
```
# 시스템 패키지 업데이트
sudo dnf update -y

# MariaDB 서버 및 클라이언트 설치
sudo dnf install -y mariadb105-server

# MariaDB 서비스 시작
sudo systemctl start mariadb

# 시스템 재시작시 자동 시작 설정
sudo systemctl enable mariadb

# 상태 확인
sudo systemctl status mariadb

# MariaDB 초기 보안을 위한 대화형 스크립트
sudo mysql_secure_installation

# 다음과 같이 설정:
# Enter current password for root (enter for none): [Enter]
# Set root password? [Y/n]: Y
# New password: [원하는 비밀번호 입력]
# Remove anonymous users? [Y/n]: Y
# Disallow root login remotely? [Y/n]: Y
# Remove test database and access to it? [Y/n]: Y
# Reload privilege tables now? [Y/n]: Y
```
<br/>


### Debezium용 MariaDB 설정
```
# CDC를 위한 mysql log를 남기기위해 [mysqld] 섹션에 설정 추가
sudo vi /etc/my.cnf.d/server.cnf
[mysqld]
server-id=1
log_bin=mysql-bin
binlog_format=ROW
binlog_row_image=FULL
expire_logs_days=3

# MariaDB 재시작
sudo systemctl restart mariadb
```
<br/>


### 테이블에 데이터 생성
```
# MariaDB 접속
mysql -u root -p

# 로그 설정 확인
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE '%binlog%';
SHOW BINARY LOGS;
SHOW MASTER STATUS;

# 다음 SQL 명령어 실행
CREATE DATABASE inventory;

USE inventory;

# customers 테이블 생성
CREATE TABLE customers (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# products 테이블 생성
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# orders 테이블 생성
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    customer_id INTEGER,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2),
    status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);
```
<br/>


### 커넥터 플러그인 다운로드
```
# confluent hub 설치
cd ~
curl -O https://packages.confluent.io/archive/7.9/confluent-7.9.1.tar.gz
tar xzf confluent-7.9.1.tar.gz

# confluent hub 설치 확인
./confluent-7.9.1/bin/confluent version

# s3 plugin 설치
./confluent-7.9.1/bin/confluent-hub install debezium/debezium-connector-mysql:3.1.2

# 설치 확인
ls /home/ec2-user/confluent-7.9.1/share/confluent-hub-components/debezium-debezium-connector-mysql/lib/
```
<br/>


### 커넥터 Path 설정
```
# 프로퍼티 파일 수정
vi config/connect-distributed.properties

# 해당 경로 추가
plugin.path=/home/ec2-user/confluent-7.9.1/share/confluent-hub-components
```
<br/>


### 커넥터 실행
```
# 커넥터 서비스 실행
./bin/connect-distributed.sh ./config/connect-distributed.properties

# 연동 플러그인 확인
curl localhost:8083/connector-plugins | jq
...
[
  {
    "class": "io.debezium.connector.mysql.MySqlConnector",
    "type": "source",
    "version": "3.1.2.Final"
  },
  ...
]
```
<br/>


### CDC 커넥트 설정
```
cd kafka_2.13-3.5.0/

vi config/connect-mysql-source.json
{
  "name": "mysql-source-connector",  
  "config": {  
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",  
    "database.hostname": "localhost",  
    "database.port": "3306",
    "database.user": "root",
    "database.password": "1234",
    "database.server.id": "1",  
    "topic.prefix": "dbserver",  
    "database.include.list": "inventory",  
    "schema.history.internal.kafka.bootstrap.servers": "localhost:9092",  
    "schema.history.internal.kafka.topic": "schema-changes.inventory"  
  }
}
```
<br/>

### 커넥터 등록
```
# 동적 커넥터 등록
curl -X POST -H "Content-Type: application/json" --data @config/connect-mysql-source.json http://localhost:8083/connectors

# 등록 확인
curl http://localhost:8083/connectors
["mysql-source-connector"]

# 등록 해지
curl -X DELETE http://localhost:8083/connectors/s3-sink-connector

# 관련 토픽 생성 확인
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
__consumer_offsets
connect-configs
connect-offsets
connect-status
dbserver
dbserver.inventory.customers
dbserver.inventory.orders
dbserver.inventory.products
schema-changes.inventory
```
<br/>


### 데이터 변경을 통해 CDC 확인
```
mysql -u root -p

USE inventory;

# customers 데이터 입력
INSERT INTO customers (first_name, last_name, email) VALUES 
    ('John', 'Doe', 'john.doe@example.com'),
    ('Jane', 'Smith', 'jane.smith@example.com'),
    ('Bob', 'Johnson', 'bob.johnson@example.com');

# products 데이터 입력
INSERT INTO products (name, description, price) VALUES
    ('Product A', 'Description for Product A', 19.99),
    ('Product B', 'Description for Product B', 29.99),
    ('Product C', 'Description for Product C', 39.99);

# orders 데이터 입력
INSERT INTO orders (customer_id, total_amount, status) VALUES 
    (1, 100.00, 'COMPLETED'),
    (2, 150.50, 'PENDING'),
    (1, 75.25, 'COMPLETED');

# customers 데이터 수정 테스트
UPDATE customers SET email = 'john.doe.updated@example.com' WHERE id = 1;

# 새로운 주문 추가 테스트
INSERT INTO orders (customer_id, total_amount, status) 
VALUES (3, 200.00, 'NEW');

# 주문 상태 변경 테스트
UPDATE orders SET status = 'SHIPPED' WHERE order_id = 2;
```
<br/>


### Kafka Consumer를 사용하여 데이터 확인
```
# customers 테이블의 변경사항 확인
./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic dbserver.inventory.customers --from-beginning

# products 테이블의 변경사항 확인
./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic dbserver.inventory.products --from-beginning

# orders 테이블의 변경사항 확인
./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic dbserver.inventory.orders --from-beginning
```
<br/>