# Matriz Oficial de Nomenclatura PAD (HEXT)

Estado: Aprobado para UI visible
Alcance actual: textos visibles de producto
No incluye aun: migracion tecnica de clases, rutas o Firestore

## Regla marco

- Contenedor general del software: Caso PAD.
- Etapa del flujo (opcional y explicita): Candidato PAD.
- Ingreso real al programa: Ingreso aprobado, Activo en PAD, No ingreso al programa, Alta, Reingreso.

## Matriz de terminos

| Termino actual | Termino nuevo | Donde aplica | Tipo |
|---|---|---|---|
| Nuevo candidato PAD | Nuevo caso PAD | CTA principal, headers, accesos de creacion | Visible |
| Candidatos PAD | Casos PAD | Titulo de modulo/listado | Visible |
| Candidatos por definir | Casos por definir | KPI y bloque operativo de dashboard | Visible |
| Candidato guardado | Caso guardado | Dialogos y confirmaciones de formulario | Visible |
| Guardar candidato | Guardar caso | Boton primario de formulario | Visible |
| Candidato aprobado para ingreso | Caso aprobado para ingreso | Snackbar y mensajes de flujo | Visible |
| Candidato revalorado | Caso revalorado | Actividad reciente | Visible |
| No hay candidatos | No hay casos | Empty states de listados | Visible |
| Crea tu primer candidato | Crea tu primer caso | Empty states de onboarding | Visible |
| Selecciona un candidato | Selecciona un caso | Mensajes de seleccion | Visible |
| No se pudo guardar el candidato | No se pudo guardar el caso | Mensajes de error | Visible |
| candidato (como objeto paraguas) | caso | Copys generales de UI y ayuda | Visible |
| Candidato PAD (etapa) | Candidato PAD (se conserva) | Estado del proceso cuando exista etapa formal | Visible |
| candidatosPad | candidatosPad (temporal) | Coleccion Firestore actual | Tecnico |
| CandidatoPad, NuevoCandidatoPad | Sin cambio por ahora | Modelos, servicios y repositorios | Tecnico |
| /pad/candidatos | Sin cambio por ahora | Ruta actual para compatibilidad | Tecnico |
| candidatos_screen.dart | Sin cambio por ahora | Nombre de archivo para evitar roturas | Tecnico |

## Estados oficiales recomendados

### Estado del proceso PAD

- Captado
- En valoracion
- Definido
- Ingreso aprobado
- Ingreso no aprobado
- Cerrado

### Situacion asistencial

- Activo en PAD
- Extension hospitalaria
- Alta
- Reingreso
- En institucion
- Sin ingreso al programa

## Criterio de uso del termino "candidato"

Usar "candidato" solo si describe una etapa explicita del proceso PAD.
No usar "candidato" como nombre general del objeto o del modulo principal.

## Plan de migracion en 3 pasos

1. UI visible: completar renombres en copys, empty states, dialogos y filtros.
2. Contrato funcional: cerrar catalogo de estados y filtros con producto/operacion.
3. Tecnico gradual: evaluar migracion de rutas, modelos y coleccion con compatibilidad temporal.
