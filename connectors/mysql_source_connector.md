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