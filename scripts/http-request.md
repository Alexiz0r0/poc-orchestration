

```shell
curl --location 'http://localhost:8087/api/config/programar/REP_10S?spName=hr.sp_migrar_datos' \
--header 'Content-Type: application/json' \
--data '{
    "salary": 5000
}'
``` 

```shell
curl --location 'http://localhost:8087/api/config/programar/REP_MIGRACION_01?cron=FREQ%3DDAILY%3BBYHOUR%3D23&spName=hr.sp_migrar_datos' \
--header 'Content-Type: application/json' \
--data '{"salary": 5000}'
``` 


```shell
curl --location 'http://localhost:8087/api/config/programar/REP_MIGRACION_SALARIOS?cron=FREQ%3DDAILY%3BBYHOUR%3D2%3BBYMINUTE%3D0' \
--header 'Content-Type: application/json' \
--data '{
    "salary": 5000,
    "area": "IT",
    "responsable": "Alexiz"
}'
``` 