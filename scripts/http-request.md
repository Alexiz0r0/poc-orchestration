

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

## Situación 1: Ejecución Inmediata
No envías ni delaySeconds ni startTime. El sistema asume el delay mínimo de seguridad.

```shell
curl -X POST "http://localhost:8087/api/config/programar/REP_NOW?spName=hr.sp_migrar_datos" \
     -H "Content-Type: application/json" -d '{"salary": 5000}'

```

## Situación 2: Ejecución con Delay (ej: 2 minutos)
Envías el parámetro delaySeconds.

```shell
curl -X POST "http://localhost:8087/api/config/programar/REP_DELAY?spName=hr.sp_migrar_datos&delaySeconds=120" \
     -H "Content-Type: application/json" -d '{"salary": 5000}'

``` 

## Situación 3: Ejecución en Horario Específico (ej: 11 PM)
Envías el parámetro startTime en formato 24h.


```shell
curl -X POST "http://localhost:8087/api/config/programar/REP_HORARIO?spName=hr.sp_migrar_datos&startTime=23:00" \
     -H "Content-Type: application/json" -d '{"salary": 5000}'

``` 