package com.alexiz.controller;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reportes")
public class ReportController {

	private static final Logger log = LoggerFactory.getLogger(ReportController.class);

	// Oracle invoca este endpoint si la migración es EXITOSA
	@PostMapping("/generar")
	public ResponseEntity<String> generarReporte(@RequestBody Map<String, String> payload) {

		if (payload == null) {
			log.warn("⚠️ El payload llegó nulo, revisa el UTL_HTTP.WRITE_TEXT");
		} else {
			log.info("✅ Payload recibido: {}", payload);
		}

		String jobName = payload.get("job_name");

		log.info("✅ ALERTA DE ORACLE: Migración completada con éxito para el job: {}", jobName);

		// Aquí iría tu lógica real: Consultar la BD y generar PDF/Excel
		log.info("Iniciando generación de PDF...");

		return ResponseEntity.ok("Generación de reporte iniciada");
	}

	// Oracle invoca este endpoint si la migración FALLA
	@PostMapping("/error")
	public ResponseEntity<String> notificarError(@RequestBody Map<String, String> payload) {

		String jobName = payload.get("job_name");

		log.error("❌ ALERTA DE ORACLE: Fallo crítico en la migración para el job: {}", jobName);

		// Aquí iría lógica de envío de correo a soporte
		log.info("Enviando correo de alerta a DBA y Soporte...");

		return ResponseEntity.ok("Alerta recibida");
	}
}