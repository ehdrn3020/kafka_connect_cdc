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
sudo dnf install -y java-17-amazon-corretto-devel

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

# 스토리지 디렉토리 설정 ( 기본값은 /tmp/kraft-combined-logs )
./bin/kafka-storage.sh format -t ghTDAhg9Q3umdlTzkI5fYw -c ./config/kraft/server.properties 

# 해당 경로에서 클러스터 ID 확인 
cat /tmp/kraft-combined-logs/meta.properties

# 카프카 브로커 실행
./bin/kafka-server-start.sh ./config/kraft/server.properties
# 또는
nohup ./bin/kafka-server-start.sh ./config/kraft/server.properties > kafka-server.log 2>&1 &
```
<br>

## 레코드 주고받기
```
# 토픽생성
/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic my-first-topic --partitions 1 --replication-factor 1

# 토픽 목록 확인
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# 토픽 삭제
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic my-first

# 프로듀서 실행
./bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic my-first-topic

# 컨슈머 실행
./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic my-first-topic
```
<br>

## 카프카 커넥터 실행
```
# 플러그인 경로 확인
ls libs/ | grep connect

# 커넥터 설정파일 확인
ls config | grep connect

# 커넥터 실행
./bin/connect-distributed.sh ./config/connect-distributed.properties

# 커넥터 관련 토픽 확인
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
connect-configs
connect-offsets
connect-status


# 파일 커넥터 플러그인 실행 

# 1) 환경변수로 CLASSPATH 설정
CLASSPATH=./libs/connect-file-3.5.0.jar ./bin/connect-distributed.sh ./config/connect-distributed.properties

# 2) plugin.path 사용 
sudo cp ./libs/connect-file-3.5.0.jar /opt/kafka/plugins/

# 설정 파일에서 플러그인 경로 지정
vi ./config/connect-distributed.properties
>>>
plugin.path=/opt/kafka/plugins

# 3) REST API를 통한 동적 로딩
curl -X PUT http://localhost:8083/connector-plugins/reload

```
<br>

## 커넥터 REST API
```
# 기본 정보 확인
curl localhost:8083
>>>
{"version":"3.5.0","commit":"ghTDAhg9Q3umdlTzkI5fYw","kafka_cluster_id":"ikAP6ezzTm6garHxeD-28B"}

# 실행 중인 커넥터 목록
curl http://localhost:8083/connectors

# 실행 중인 플러그인 확인
curl localhost:8083/connector-plugins | jq
```
<br/>

## 파일 커넥터 예제
```
# 파일 커넥터 설정 파일 생성
vi sink-config.json
{
  "name":"file-sink",
  "connector.class":"org.apache.kafka.connect.file.FileStreamSinkConnector",
  "tasks.max":"1",
  "topics":"topic-to-export",
  "file":"/tmp/sink.out",
  "value.converter":"org.apache.kafka.connect.storage.StringConverter"
}

# 파일 커넥터에 사용할 토픽 생성
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --replication-factor 1 --partitions 1 --topic topic-to-export

# 커넥터 실행
curl -X PUT -H "Content-Type: application/json" -d @sink-config.json localhost:8083/connectors/file-sink/config

# 커넥터 상태 확인
curl localhost:8083/connectors/file-sink
>>>
{
  "name":"file-sink",
  "config":{
    "connector.class":"org.apache.kafka.connect.file.FileStreamSinkConnector",
    "file":"/tmp/sink.out",
    "tasks.max":"1",
    "topics":"topic-to-export",
    "name":"file-sink",
    "value.converter":"org.apache.kafka.connect.storage.StringConverter"
  },
  "tasks":[
    {"connector":"file-sink","task":0}
  ],
  "type":"sink"
}

# 데이터 input 확인하기위한 파일 테일링
tail -f /tmp/sink.out

# 프로듀서를 통해 토픽에 레코드 추가
./bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic topic-to-export
>first record! 1
>secont record!! 2
>third recordddddd
```
