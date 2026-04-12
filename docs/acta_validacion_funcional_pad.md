# Acta de validacion funcional PAD - Checklist operador

Fecha: 11/04/2026
Entorno: Chrome / Windows
Build: local
Validador: ___

## Criterios de pase generales

- No permite guardar con cero motivos activos.
- El motivo principal siempre pertenece a los activos.
- Al desactivar un motivo, su detalle no vuelve a persistirse.
- Editar actualiza el mismo documento, no crea uno nuevo.
- El listado muestra principal y activos con labels legibles.
- Los casos legado se abren sin error y se enriquecen al reguardar.

## Caso 1

Caso a probar: Un motivo

Datos a ingresar:

- Motivo activo: Finalizar tratamiento
- Motivo principal: Finalizar tratamiento
- Fecha probable finalizacion: ___
- Estado: En curso / Finalizado
- Observaciones: ___

Pasos:

1. Ir a nuevo caso PAD.
2. Completar datos minimos obligatorios del formulario.
3. Activar solo Finalizar tratamiento.
4. Elegir Finalizar tratamiento como principal.
5. Completar fecha, estado y observaciones.
6. Guardar.
7. Abrir el mismo documento y verificar hidratacion.

Resultado esperado:

- Guarda sin error.
- Firestore contiene motivoIngresoPrincipal.
- Firestore contiene motivosIngresoActivos con 1 valor.
- Firestore contiene detalleMotivos.finalizar_tratamiento.
- Firestore conserva motivos legado.
- Al reabrir, hidrata igual.

Resultado obtenido: ___
Estado: OK / FAIL / BLOCKER
Observaciones: ___

## Caso 2

Caso a probar: Dos motivos

Datos a ingresar:

- Motivos activos: Clinica de heridas + Procedimiento pendiente
- Motivo principal: ___
- Heridas frecuencia: ___
- Heridas sesiones planeadas: ___
- Heridas sesiones realizadas: ___
- Procedimiento 1 nombre: ___
- Procedimiento 1 estado: Pendiente / Realizado

Pasos:

1. Crear nuevo caso PAD.
2. Completar datos minimos obligatorios.
3. Activar Clinica de heridas y Procedimiento pendiente.
4. Seleccionar uno de los dos como principal.
5. Completar detalle de heridas.
6. Agregar un procedimiento con estado.
7. Guardar.
8. Reabrir, editar un campo menor y volver a guardar.

Resultado esperado:

- Ambos quedan en motivosIngresoActivos.
- El principal queda dentro de activos.
- Se guardan ambos bloques de detalle.
- No se pierde informacion tras editar y reguardar.

Resultado obtenido: ___
Estado: OK / FAIL / BLOCKER
Observaciones: ___

## Caso 3

Caso a probar: Tres motivos

Datos a ingresar:

- Motivos activos: los tres
- Motivo principal: ___
- Completar detalle de los tres bloques

Pasos:

1. Crear nuevo caso PAD.
2. Completar datos minimos obligatorios.
3. Activar los tres motivos.
4. Definir principal valido.
5. Completar detalle de finalizar tratamiento.
6. Completar detalle de clinica de heridas.
7. Completar detalle de procedimiento pendiente.
8. Guardar.
9. Reabrir y verificar hidratacion de los tres bloques.
10. Validar en listado principal y activos legibles.

Resultado esperado:

- Se persisten 3 activos.
- Se persiste 1 principal valido.
- Se guardan 3 detalles.
- Reapertura sin perdida de datos.
- Listado legible para principal y activos.

Resultado obtenido: ___
Estado: OK / FAIL / BLOCKER
Observaciones: ___

## Caso 4

Caso a probar: Caso legado

Datos a ingresar:

- Documento legado con solo motivos.

Pasos:

1. Abrir documento legado desde listado.
2. Verificar que no falle la carga del formulario.
3. Confirmar principal tomado desde motivos.first.
4. Confirmar fallback de activos.
5. Reguardar.
6. Revisar documento actualizado en Firestore.

Resultado esperado:

- Apertura sin error.
- Principal inferido correctamente.
- Activos inferidos correctamente.
- Tras reguardar se agregan:
- motivoIngresoPrincipal
- motivosIngresoActivos
- detalleMotivos

Resultado obtenido: ___
Estado: OK / FAIL / BLOCKER
Observaciones: ___

## Caso 5

Caso a probar: Procedimientos multiples

Datos a ingresar:

- Motivo activo: Procedimiento pendiente
- Cantidad inicial de procedimientos: 3

Pasos:

1. Crear nuevo caso PAD.
2. Activar Procedimiento pendiente.
3. Agregar 3 procedimientos (nombre, fecha, estado, observacion).
4. Eliminar 1 procedimiento.
5. Guardar.
6. Reabrir y validar cantidad y contenido.
7. Editar 1 procedimiento y reguardar.
8. Reabrir de nuevo y validar reconstruccion.

Resultado esperado:

- Funciona agregar y eliminar.
- No quedan duplicados.
- Se conserva orden razonable.
- Persisten nombre, fecha, estado y observacion.
- Reapertura reconstruye lista correctamente.

Resultado obtenido: ___
Estado: OK / FAIL / BLOCKER
Observaciones: ___

## Resultado global

- Casos aprobados: ___ / 5
- Casos con FAIL: ___
- Casos con BLOCKER: ___
- Decision:
- [ ] Aprobado para continuar
- [ ] Aprobado con ajustes menores
- [ ] Requiere correcciones antes de seguir

## Hallazgos tecnicos

1. ---
2. ---
3. ---

## Proxima accion

- [ ] Ajustar bug(s)
- [ ] Cerrar resumen compacto del caso
- [ ] Generar version semaforo ejecutivo
