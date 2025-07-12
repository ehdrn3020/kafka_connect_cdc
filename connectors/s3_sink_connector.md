# S3 Confluent Connector
<br/>


### S3 버킷 생성
```
bucket name = kafka-sink-data
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
./confluent-7.9.1/bin/confluent-hub install confluentinc/kafka-connect-s3:10.6.6
>>> All Question's answer is 'y'

# 설치 확인
ls /home/ec2-user/confluent-7.9.1/share/confluent-hub-components/confluentinc-kafka-connect-s3/lib

# 환경변수 설정 (선택)
export CONFLUENT_HOME=~/kafka_2.13-3.5.0/confluent-7.9.1
export PATH=$PATH:$CONFLUENT_HOME/bin
```
설치 참조 
- https://docs.confluent.io/platform/current/installation/installing_cp/zip-tar.html
<br/>


### 플러그인 검색
어떤 plugin을 confluent에서 설치할 수 있는지 검색가능
- https://www.confluent.io/hub/
<br/>


### 커넥터 설정파일 생성
```
cd kafka_2.13-3.5.0/

vi config/connect-s3-sink.json

# DefaultPartitioner 파티션 클래스 사용시
{
  "name": "s3-sink-connector",
  "config": {
    "connector.class": "io.confluent.connect.s3.S3SinkConnector",
    "tasks.max": "1",
    "topics": "orders",
    "s3.bucket.name": "kafka-sink-data",
    "s3.region": "ap-northeast-2",
    "storage.class": "io.confluent.connect.s3.storage.S3Storage",
    "aws.access.key.id": "${}",
    "aws.secret.access.key": "${}",
    "format.class": "io.confluent.connect.s3.format.json.JsonFormat",
    "flush.size": "1",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "partitioner.class": "io.confluent.connect.storage.partitioner.DefaultPartitioner",
    "rotate.schedule.interval.ms": "60000",
    "timezone": "Asia/Seoul"
  }
}

# TimeBasedPartitioner 파티션 클래스 사용시
{
  "name": "s3-sink-connector",
  "config": {
    "connector.class": "io.confluent.connect.s3.S3SinkConnector",
    "tasks.max": "3",
    "flush.size": "1",
    "topics": "orders",
    "s3.bucket.name": "kafka-sink-data",
    "s3.region": "ap-northeast-2",
    "storage.class": "io.confluent.connect.s3.storage.S3Storage",
    "aws.access.key.id": "${}",
    "aws.secret.access.key": "${}",
    "format.class": "io.confluent.connect.s3.format.json.JsonFormat",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "partitioner.class": "io.confluent.connect.storage.partitioner.TimeBasedPartitioner",
    "timestamp.extractor": "RecordField",
    "timestamp.field": "dt",
    "timestamp.parser": "yyyy-MM-dd",
    "path.format": "'year'=YYYY/'month'=MM/'day'=dd",
    "partition.duration.ms": "86400000",
    "locale": "ko_KR",
    "timezone": "Asia/Seoul",
    "rotate.schedule.interval.ms": "60000"
  }
}

# mysql cdc topic
{
  "name": "s3-sink-connector",
  "config": {
    /* ---------- 필수 정보 ---------- */
    "connector.class"          : "io.confluent.connect.s3.S3SinkConnector",
    "tasks.max"                : "1",
    "topics"                   : "dbserver.inventory.customers",
    "s3.bucket.name"           : "kafka-sink-data",
    "s3.region"                : "ap-northeast-2",
    "storage.class"            : "io.confluent.connect.s3.storage.S3Storage",
    "aws.access.key.id"        : "<AWS_ACCESS_KEY>",
    "aws.secret.access.key"    : "<AWS_SECRET_KEY>",
    /* ---------- 메시지 포맷 ---------- */
    "format.class"             : "io.confluent.connect.s3.format.json.JsonFormat",
    "value.converter"          : "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable" : "false",
    "key.converter"            : "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable"   : "false",
    /* ---------- 파티셔닝(선택) ---------- */
    "partitioner.class"        : "io.confluent.connect.storage.partitioner.TimeBasedPartitioner",
    "timestamp.extractor"      : "RecordField",
    "timestamp.field"          : "dt",
    "timestamp.parser"         : "yyyyMMdd",
    "partition.duration.ms"    : "86400000",
    "path.format"              : "'yymmdd='yyyyMMdd",
    /* ---------- 파일 회전 ---------- */
    "flush.size"               : "10",
    "rotate.schedule.interval.ms": "600000",
    "timezone": "Asia/Seoul",
    "locale":   "ko_KR", 
    /* ---------- Debezium 메시지 언랩 ---------- */
    "transforms"                       : "unwrap",
    "transforms.unwrap.type"           : "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "true",
  }
}


### 각 옵션 설명 ###

# 해당 커넥터에 대해 생성될 수 있는 최대 태스크 수
# 각 태스크는 토픽의 서로 다른 파티션을 처리합니다
# 데이터 처리 속도와 처리량이 향상됩니다
"tasks.max": "3",

"storage.class": "io.confluent.connect.s3.storage.S3Storage" // Kafka Connect가 데이터를 저장할 스토리지 시스템을 지정하는 설정
"partitioner.class": "io.confluent.connect.storage.partitioner.TimeBasedPartitioner"  // 시간 기반 파티셔닝
"timestamp.extractor": "RecordField"    // 레코드 필드에서 시간 정보 추출
"timestamp.field": "dt"                 // 시간 정보가 있는 필드 이름
"timestamp.parser": "yyyy-MM-dd"        // 날짜 형식 지정
"path.format": "'year'=YYYY/'month'=MM/'day'=dd"  // S3 경로 형식
"partition.duration.ms": "86400000"     // 파티션 기간 (1일 = 86400000ms)
"locale": "ko_KR"                       // 로케일 설정
"timezone": "Asia/Seoul"                // 시간대 설정
"rotate.schedule.interval.ms": "60000"  // 파일 로테이션 주기 (1분 = 60000ms)
```
<br/>


### 다른 옵션
```
# 저장 파일 압축 관련 ( 선택 )
"format.class": "io.confluent.connect.s3.format.parquet.ParquetFormat",
"parquet.codec": "snappy",

# FieldPartitioner 사용시
"partitioner.class": "io.confluent.connect.storage.partitioner.FieldPartitioner",
"partition.field.name": "dt",
"path.format": "dt=${value}"

# FieldPartitioner 옵션을 사용하기 위해서는 데이터를 보낼 때는 스키마 정보를 포함한 형식으로 보내야 함
# 예시
./bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic orders --property parse.key=true --property key.separator=:
>2:{"schema":{"type":"struct","fields":[{"type":"string","optional":false,"field":"order_id"},{"type":"string","optional":false,"field":"customer_id"},{"type":"string","optional":false,"field":"book_id"},{"type":"int32","optional":false,"field":"quantity"},{"type":"double","optional":false,"field":"price"},{"type":"string","optional":false,"field":"dt"}]},"payload":{"order_id":"2","customer_id":"124","book_id":"457","quantity":1,"price":15.99,"dt":"2023-10-02"}}

# 멱등성
중복없이 동일한 레코드의 멱등성을 보장하기 위해서는 토픽 레벨의 로그 컴팩션을 적용하면 된다.
카프카 컨넥트 레벨에서는 저장되는 s3 파일명에 key값을 포함하도록 수정하여 가장 최근 데이터만 유효하도록 하는 방법이 있다. 
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
    "class": "io.confluent.connect.s3.S3SinkConnector",
    "type": "sink",
    "version": "10.6.6"
  },
  ...
]
```
<br/>


### 커넥터 등록
```
# 동적 커넥터 등록
curl -X POST -H "Content-Type: application/json" --data @config/connect-s3-sink.json http://localhost:8083/connectors

# 등록 확인
curl http://localhost:8083/connectors
["s3-sink-connector"]

# 등록 해지
curl -X DELETE http://localhost:8083/connectors/s3-sink-connector
```
<br/>


### 토픽생성
```
# 3개의 파티션으로 구성된 orders 토픽 생성
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic orders --partitions 3 --replication-factor 1
```
<br/>


### 레코드 생성
```
# 토픽에 레코드 생성
./bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic orders --property key.separator=:
./bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic orders
>>> 데이터 입력
1:{"order_id": "1", "customer_id": "123", "book_id": "456", "quantity": 2, "price": 29.99, "dt": "2023-10-01"}
2:{"order_id": "2", "customer_id": "124", "book_id": "457", "quantity": 1, "price": 15.99, "dt": "2023-10-02"}
3:{"order_id": "3", "customer_id": "125", "book_id": "458", "quantity": 3, "price": 45.00, "dt": "2023-10-03"}

# 전송 에러 없는지 확인
curl http://localhost:8083/connectors/s3-sink-connector/status

# s3 확인
# DefaultPartitioner 파티션 클래스 사용시
s3://kafka-sink-data/topics/orders/partition=0/${topic}+${partition}+${offest}.json

# TimeBasedPartitioner 파티션 클래스 사용시
s3://kafka-sink-data/orders/year=2023/month=10/day=01/${topic}+${partition}+${offest}.json


# 저장 경로 구조
kafka-sink-data: S3 버킷 이름
topics: 기본 디렉토리 접두사
orders: Kafka 토픽 이름
partition=0: Kafka 파티션 번호
orders+0+0000000000.json: 파일명 형식 (토픽이름+파티션+오프셋.확장자)
```
<br/>