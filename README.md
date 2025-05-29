# kafka_connect_cdc
Kafka Connect를 활용하여 MySQL, Elasticsearch 실시간 CDC
<br>

## AWS Server Setting
### .env 파일 생성
- setting_aws/env_example 참조하여 생성

### keypair.pem 키 생성
- ec2 접속을 위해 keypair.pem 키를 setting_aws 폴더에 생성
- 파일 권한 수정 : sudo chmod 600 setting_aws/keypair.pem

### EC2 서버 실행
```commandline
sh setting_aws/setup_server.sh server_1
sh setting_aws/setup_server.sh server_2
sh setting_aws/setup_server.sh server_3
```

### scp keypair.pem
```commandline
scp -i setting_aws/keypair.pem setting_aws/keypair.pem ec2-user@server_1_ip:~
```

### SSH 접속
```commandline
ssh -i setting_aws/keypair.pem ec2-user@server_1_ip
```
<br>


## Java 설치
```
# java 17 설치 ( kafak 3.5.0 과 호환 )
sudo yum install -y java-17-amazon-corretto-devel

# JAVA_HOME 환경변수 설정
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 환경변수 확인
echo $JAVA_HOME
```
<br>


## Kafka 설치
```
# 크래프트 모드의 kafka 3.5.0 설치
wget https://archive.apache.org/dist/kafka/3.5.0/kafka_2.13-3.5.0.tgz
tar zxvf kafka_2.13-3.5.0.tgz
cd kafka_2.13-3.5.0/

# 클러스터 ID를 생성
./bin/kafka-storage.sh random-uuid
>>> ghTDAhg9Q3umdlTzkI5fYw
# 해당 경로에서 클러스터 ID 확인 
cat /tmp/kraft-combined-logs/meta.properties


# 스토리지 디렉토리 설정 ( 기본값은 /tmp/kraft-combined-logs )
./bin/kafka-storage.sh format -t ghTDAhg9Q3umdlTzkI5fYw \
> -c ./config/kraft/server.properties 

# 카프카 브로커 실행
./bin/kafka-server-start.sh ./config/kraft/server.properties
```
<br>
