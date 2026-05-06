package com.alexiz.controller;

import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.core.JsonProcessingException;

import tools.jackson.databind.ObjectMapper;

@RestController
@RequestMapping("/api/config")
public class OrchesV4ConfigController {

	private final JdbcTemplate jdbcTemplate;
	private final ObjectMapper objectMapper;

	public OrchesV4ConfigController(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
		this.jdbcTemplate = jdbcTemplate;
		this.objectMapper = objectMapper;
	}

	@PostMapping("/programar/{reportId}")
	public String programarJob(@PathVariable String reportId, @RequestParam String spName,
			@RequestParam(required = false) Integer delaySeconds, @RequestParam(required = false) String startTime,
			// Formato "HH:mm" ej: "18:30"
			@RequestBody Map<String, Object> params) throws JsonProcessingException {

		String jsonParams = objectMapper.writeValueAsString(params);
		long finalDelay = 0;

		// LÓGICA DE TIEMPO DINÁMICA
		if (startTime != null && !startTime.isEmpty()) {
			// Situación: Horario específico (HH:mm)
			finalDelay = calcularDelayHastaHora(startTime);
		} else if (delaySeconds != null) {
			// Situación: Ejecución con delay relativo
			finalDelay = delaySeconds;
		} else {
			// Situación: Ejecución inmediata (le damos 2s para asegurar el COMMIT de la
			// tabla)
			finalDelay = 2;
		}

		// 1. MERGE en tabla de control (Igual que antes)
		jdbcTemplate.update("""
				MERGE INTO hr.report_jobs_config c
				USING dual ON (c.report_id = ?)
				WHEN MATCHED THEN
				    UPDATE SET parametros_json = ?, sp_name = ?, status = 'PENDIENTE', last_run = SYSTIMESTAMP
				WHEN NOT MATCHED THEN
				    INSERT (report_id, job_name, parametros_json, sp_name, status, last_run)
				    VALUES (?, ?, ?, ?, 'PENDIENTE', SYSTIMESTAMP)
				""", reportId, jsonParams, spName, reportId, "JOB_" + reportId, jsonParams, spName);

		// 2. Orquestación en Oracle
		String jobName = "JOB_" + reportId;
		String plsql = """
				 BEGIN
				    BEGIN DBMS_SCHEDULER.DROP_JOB(?); EXCEPTION WHEN OTHERS THEN NULL; END;

				    DBMS_SCHEDULER.CREATE_JOB (
				        job_name            => ?,
				        job_type            => 'PLSQL_BLOCK',
				        job_action          => 'BEGIN hr.sp_master_orquestador(''' || ? || '''); END;',
				        start_date          => SYSTIMESTAMP + NUMTODSINTERVAL(?, 'SECOND'),
				        enabled             => TRUE,
				        auto_drop           => TRUE
				    );
				END;
				""";

		jdbcTemplate.update(plsql, jobName, jobName, reportId, finalDelay);

		return "✅ Reporte [" + reportId + "] programado. Inicia en: " + finalDelay + " segundos.";
	}

	// Función auxiliar para calcular segundos faltantes hasta una hora HH:mm
	private long calcularDelayHastaHora(String startTime) {
		java.time.LocalTime now = java.time.LocalTime.now();
		java.time.LocalTime target = java.time.LocalTime.parse(startTime);

		java.time.Duration duration = java.time.Duration.between(now, target);

		// Si la hora ya pasó hoy, se programa para mañana
		if (duration.isNegative()) {
			duration = duration.plusDays(1);
		}

		return duration.getSeconds();
	}
}