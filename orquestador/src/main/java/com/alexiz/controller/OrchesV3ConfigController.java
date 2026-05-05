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
public class OrchesV3ConfigController {

	private final JdbcTemplate jdbcTemplate;
	private final ObjectMapper objectMapper;

	public OrchesV3ConfigController(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
		this.jdbcTemplate = jdbcTemplate;
		this.objectMapper = objectMapper;
	}

	@PostMapping("/programar/{reportId}")
	public String programarJob(@PathVariable String reportId, @RequestParam String spName,
			@RequestParam(defaultValue = "5") int delaySeconds, // Por defecto 5 seg
			@RequestBody Map<String, Object> params) throws JsonProcessingException {

		String jsonParams = objectMapper.writeValueAsString(params);

		// 1. MERGE: Ahora incluimos el estado inicial 'PENDIENTE'
		jdbcTemplate.update("""
				MERGE INTO hr.report_jobs_config c
				USING dual ON (c.report_id = ?)
				WHEN MATCHED THEN
				    UPDATE SET parametros_json = ?, sp_name = ?, status = 'PENDIENTE', last_run = SYSTIMESTAMP
				WHEN NOT MATCHED THEN
				    INSERT (report_id, job_name, parametros_json, sp_name, status, last_run)
				    VALUES (?, ?, ?, ?, 'PENDIENTE', SYSTIMESTAMP)
				""", reportId, jsonParams, spName, reportId, "JOB_" + reportId, jsonParams, spName);

		// 2. Lógica de Tiempo Dinámica
		// Aquí podrías añadir lógica: si el usuario manda una hora fija, calculas la
		// diferencia.
		// Por ahora, usamos el delaySeconds solicitado.
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
				        auto_drop           => TRUE -- Se elimina solo de Scheduler, no de nuestra tabla
				    );
				END;
				""";

		jdbcTemplate.update(plsql, jobName, jobName, reportId, delaySeconds);

		return "✅ Reporte [" + reportId + "] programado para iniciar en " + delaySeconds + " segundos.";
	}
}