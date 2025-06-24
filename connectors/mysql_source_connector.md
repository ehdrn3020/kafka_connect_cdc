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

# MariaDB 보안 설정
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

### Debezium용 MariaDB 설정
```
sudo vi /etc/my.cnf.d/server.cnf

# [mysqld] 섹션에 다음 내용 추가
[mysqld]
server-id=1
log_bin=mysql-bin
binlog_format=ROW
binlog_row_image=FULL
expire_logs_days=3

# MariaDB 재시작
sudo systemctl restart mariadb

# MariaDB 접속
mysql -u root -p
```

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