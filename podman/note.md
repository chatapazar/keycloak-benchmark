export KEYCLOAK_HOME=/Users/ckongman/work/workspace/keycloak


./kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin_password

edit master realms --> realm setting --> tokens --> access token lifespan to 30minutes
create test realm
create client 'test-client'

curl -X POST 'http://keycloak-service.test.svc.cluster.local:8080/realms/test/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'client_id=test-client' \
  -d 'grant_type=password' \
  -d 'username=user1' \
  -d 'password=user1-password' \
  -d 'scope=openid'



  curl -v 'http://keycloak-service.test.svc.cluster.local:9000/health/ready'