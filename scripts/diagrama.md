https://mermaid.live/

```shell
sequenceDiagram
    autonumber
    participant C as Cliente (Postman/Frontend)
    participant J as Java API (Spring Boot)
    participant T as Tabla Control (Oracle)
    participant S as DBMS_SCHEDULER (Oracle)
    participant M as SP_MASTER (Worker)

    Note over C, J: T0: Solicitud de Reporte
    C->>J: POST /api/config/programar/{id}
    
    Note over J, T: Persistencia de Intención
    J->>T: MERGE (Status: PENDIENTE, Payload JSON)
    
    Note over J, S: Desacoplamiento Temporal
    J->>S: DBMS_SCHEDULER.CREATE_JOB (Delay Xs)
    
    Note over J, C: Respuesta Inmediata
    J-->>C: 202 Accepted (ID del Proceso)

    Note over S, M: T+Xs: Activación del Job
    S->>M: Ejecuta sp_master_orquestador(id)
    
    Note over M, T: Cambio de Estado
    M->>T: UPDATE (Status: EN_PROCESO)
    
    Note over M: Ejecución Lógica Pesada (SP_NEGOCIO)
    
    alt Éxito
        M->>T: UPDATE (Status: COMPLETADO)
        M->>J: HTTP POST /notificar (Success)
    else Error
        M->>T: UPDATE (Status: ERROR, MSG_ERR)
        M->>J: HTTP POST /notificar (Failure)
    end
    
    Note over J: Post-Procesamiento (PDF/Email)

``` 

https://www.plantuml.com/plantuml/


```sql
@startuml
skinparam style strictuml
skinparam sequenceMessageAlign center

actor "Cliente\n(Postman)" as Client
participant "Java API\n(Spring Boot)" as Java
database "Tabla Control\n(Oracle)" as Table
entity "DBMS_SCHEDULER\n(Oracle)" as Scheduler
participant "SP_MASTER\n(Worker)" as Master

== Fase de Programación (Síncrona) ==

Client -> Java : POST /programar (reportId, params)
activate Java
Java -> Table : MERGE (Status: PENDIENTE, JSON)
Java -> Scheduler : CREATE_JOB (delay_seconds)
Java --[#green]> Client : 202 Accepted (ID: report_id)
deactivate Java

== Fase de Ejecución (Asíncrona) ==

... Espera de X segundos ...

Scheduler -> Master : Inicia sp_master_orquestador()
activate Master
Master -> Table : UPDATE status = 'EN_PROCESO'
note over Master : Ejecución dinámica de\nSP de Negocio (Migración)

alt #LightGreen Éxito
    Master -> Table : UPDATE status = 'COMPLETADO'
    Master -> Java : CallBack (HTTP POST /notificar success)
else #Pink Error
    Master -> Table : UPDATE status = 'ERROR' (SQLERRM)
    Master -> Java : CallBack (HTTP POST /notificar error)
end

deactivate Master
note right of Java : Generación de PDF\no envío de alertas

@enduml
``` 