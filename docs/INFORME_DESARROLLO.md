# V4.1: qué se realizó, cómo, herramientas y fuentes

Documentación añadida el **13 de octubre de 2026**. Resume la nueva copia de V4, sus cálculos y sus pruebas. Esta actualización documental conserva los binarios, trayectorias, campos CFD y ZIP portable publicados.

## 1. Objetivo y referencia

Se iteró la simulación para mejorar la interacción entre aceite y mecanismo y la representación de las señales de sensores. Se mantienen dos variables de estudio: **litros de aceite** y **cantidad de sondas**. El giro, temperatura, gravedad, geometría y demás condiciones del caso medido permanecen constantes.

La referencia es la rueda motorizada **930E-4SE**. El fabricante publica motor de inducción AC GDY106, relación 32,62:1 y 95 L por caja reductora. El modelo utiliza dimensiones y dientes ilustrativos; esas especificaciones no acreditan el CAD interno ni se trasladan automáticamente al 980E. [Komatsu, página 2](https://www.komatsu.com/content/dam/komatsu/websites/oceania/documents/brochures/dump-trucks/930e-4se.pdf).

## 2. Qué se realizó respecto a V4

- Copia independiente obtenida del ZIP de V4 y verificada contra **2585 huellas**. [Registro](../reports/v4_copy_verified.json).
- Corrección del término de divergencia para usar velocidad relativa fluido/pared móvil.
- Proyección hacia la cara más cercana del diente, incluyendo flancos y normales.
- Viscosidad en unidades SI, tensión superficial con valor supuesto de 0,030 N/m y adhesión de pared empírica.
- Preparación de 3 s de asentamiento y 2 s de arranque gradual; después, **20 s de medición** a giro constante.
- Motor nativo Rust para cálculo y motor WebAssembly autónomo como alternativa portable.
- Sondas con exclusión de metal, capacitancia coaxial analítica, película residual auxiliar, retardo y ruido por canal.
- Dashboard de señales, superficie visual suave, partículas físicas, CSV y un panel con datos reales de un banco OpenFOAM independiente.
- Estudios de resolución de 32/16/8 mm con sus resultados y rechazos documentados.

### Casos SPH entregados

| Aceite | Partículas | Masa | Ventana medida | Sondas seleccionables |
|---|---:|---:|---:|---|
| 55 L | 2098 | 49,5 kg | 20 s | 2–12 |
| 95 L | 3624 | 85,5 kg | 20 s | 2–12 |
| 125 L | 4768 | 112,5 kg | 20 s | 2–12 |

Cada trayectoria contiene 1001 cuadros a 50 Hz. Los quince CSV predefinidos corresponden a 2/4/6/8/12 sondas por volumen. Los volúmenes nuevos entre 30 y 145 L requieren otro cálculo. Seleccionar más sondas observa el mismo fluido; no modifica su trayectoria.

## 3. Cómo se implementó

### Aceite y mecanismo

Se mantienen dos etapas planetarias ilustrativas, de dientes 18/27/72 y 23/52/127, reducción total 32,60869565:1, con giro del eje a 300 rpm. Las fronteras reciben velocidad de traslación y rotación en cada paso. Salva resuelve DFSPH; el código propio incorpora viscosidad y fuerzas superficiales, contacto geométrico y paso adaptativo externo por velocidad.

La carcasa fija tiene radio 0,5 m y longitud 0,9 m. La separación usada es **32 mm**, con radio de partícula 16 mm. Densidad 900 kg/m³, temperatura 60 °C, viscosidad 264,238 cSt y gravedad 9,81 m/s² son condiciones/supuestos del estudio. La fase de preparación se incorpora al ángulo del mecanismo para sincronizar la vista y el fluido. [Motor](../engine/src/), [Salva modificado](../build/salva/).

### Sensores y dashboard

1. Se evalúa ocupación alrededor de cada sonda y se excluye el volumen ocupado por metal. Una zona totalmente sólida produce lectura no disponible.
2. Una aproximación de conectividad distingue ocupación conectada al fondo y desconectada; depende de la resolución y no identifica espuma de forma validada.
3. Se aplica un modelo eléctrico coaxial. Para un medio homogéneo, `C = 2*pi*epsilon0*epsilon_r*L/ln(b/a) + C_parasita`. La implementación integra capas radiales para la película auxiliar. Radios 4/6 mm, longitud 25 mm, permitividad del aceite 2,2 y capacitancia parásita 8 pF son supuestos.
4. Se modela una película residual mediante una ecuación auxiliar, con objetivo de 50 µm multiplicado por ocupación, límite 150 µm y tiempos de humectación/drenaje 0,1/0,7 s. No es una película microscópica resuelta por SPH.
5. La electrónica usa respuesta de 80 ms y ruido de 0,01 pF, con semillas independientes. El visor ofrece aceite/aire inferido, conectividad, película, capacitancia y columna calculada del campo.

[Modelo de sondas](../dashboard/sensor-model.js), [condiciones](../dashboard/constants.js), [servidor](../server.mjs), [resultados](../data/volumes/). La columna integra el campo completo; no es una medición de nivel global obtenida solo desde el electrodo puntual. La suavización de superficie mejora el aspecto visual y no aumenta la resolución física.

### Referencia bifásica separada

OpenFOAM `interFoam` calculó un banco 3D cerrado de **1 × 0,8 × 0,5 m**, 2560 celdas y 95 L, con una pared plana de velocidad tangencial 0,7 m/s. Se calcularon **3 s totales**, con 1 s de preparación y **2 s medidos**. VOF calcula las fracciones de aceite/aire y la velocidad/presión de mezcla. [Descripción oficial de interFoam](https://doc.openfoam.com/2312/tools/processing/solvers/rtm/multiphase/interFoam/).

El banco aproxima cizalla local de una superficie móvil. Su geometría y sondas C1–C12 son distintas del reductor y las sondas S1–S12. El aire es incompresible e isotérmico. La presión es relativa al punto de referencia del solver. Su capacitancia es ideal, sin película ni electrónica del modelo SPH. El dashboard lee los campos y sondas realmente calculados, conservados en [cfd](../cfd/).

Los intentos bifásicos del reductor completo y rotor anular divergieron y fueron descartados. El banco aceptado **no valida dientes, órbitas ni lubricación del wheel motor completo**. [Investigación y resultados](../research/v41.md).

## 4. Herramientas utilizadas y estado

| Herramienta | Uso real | Estado / licencia |
|---|---|---|
| Rust, Cargo y enlazador GNU | Motor propio, binario nativo y pruebas | Utilizados; fuentes y avisos incluidos |
| Salva 0.10.0 | Solver DFSPH con modificaciones documentadas | Integrado; Apache-2.0 |
| Rayon / Crossbeam | Paralelismo del cálculo nativo | Integrados; MIT/Apache-2.0 |
| WebAssembly | Alternativa autónoma del motor | Probada, sin importaciones externas |
| Node.js | Servidor, cálculo y exportaciones | Probado con 24.18.0; requisito 22+; MIT y terceros |
| Three.js r180 / WebGL2 | Escena y superficie | Integrados; Three.js MIT |
| Noto Sans | Tipografía local | OFL-1.1 |
| OpenFOAM 1912.200626 | Banco bifásico VOF | Ejecutado; GPL-3+; configuración del caso GPL-3.0-or-later |
| Debian 12 y QEMU 11.1 | Entorno Linux local para OpenFOAM | Utilizados; QEMU mediante emulación TCG; no servidor externo |
| Python | Generación y exportación del banco CFD, empaquetado y hashes | Utilizado; herramientas auxiliares de biblioteca estándar |
| Git y GitHub CLI | Publicación de la copia y paquetes | Utilizados; repositorio privado |
| Elmer FEM | Alternativa electrostática estudiada | Investigado; no integrado ni ejecutado |

[Avisos y licencias](../THIRD_PARTY_NOTICES.md), [auditoría](../open_source_audit.json) y [estado de herramientas](../reports/tools_status.json) detallan versiones, componentes y alcance. Las claves, discos de la VM y descargas de investigación quedaron fuera del paquete. La aplicación usa datos locales y no necesita un servicio comercial de simulación.

## 5. Comprobaciones, resultados y rechazos

| Grupo | Evidencia preservada | Resultado |
|---|---|---|
| Física y geometría Rust | [rust_tests.log](../reports/rust_tests.log) | 11 pruebas aprobadas |
| Sondas | [sensor_tests.json](../reports/sensor_tests.json) | 5 pruebas aprobadas |
| Trayectorias, API, CSV, acoplamiento y equivalencia de motores | [verification_v41.json](../reports/verification_v41.json) | 26 comprobaciones aprobadas |
| Banco aceite/aire | [cfd_shear_validation.json](../reports/cfd_shear_validation.json) | 9 controles aprobados |
| Resolución | [refinement_v41.json](../reports/refinement_v41.json) | No demuestra convergencia |

Los casos de 20 s conservan masa y partículas y cumplen los límites de finitud, contención, penetración, velocidad y corrección definidos. La comparación corta con mecanismo detenido cambia las trayectorias y la energía. La equivalencia nativo/WebAssembly corresponde a un ensayo corto; la preparación del motor WebAssembly aproxima la rampa en tramos de 10 ms.

En el banco CFD, el error máximo de inventario fue **0,00000401 %** y la energía interna creció por el movimiento de la pared. Son controles numéricos, no precisión experimental certificada.

Los ensayos iniciales de 16/8 mm duran 20 ms. El ensayo preparado de 16 mm fue rechazado por velocidad y corrección excesivas. Por eso se conservaron 32 mm para los tres casos completos. El cálculo simultáneo de estos casos tardó aproximadamente 32–44 minutos en el PC utilizado; no es un benchmark de nube.

## 6. Fuentes y aporte

| Fuente | Uso |
|---|---|
| [Komatsu 930E-4SE](https://www.komatsu.com/content/dam/komatsu/websites/oceania/documents/brochures/dump-trucks/930e-4se.pdf) | Capacidad, reducción y arquitectura publicadas |
| [DFSPH, Bender y Koschier, 2015](https://animation.rwth-aachen.de/publication/054/) | Fundamento de incomprensibilidad y divergencia |
| [Salva, fuente oficial](https://github.com/dimforge/salva) | Base del motor y licencia; revisión fijada en el proyecto |
| [Morris, Fox y Zhu, 1997](https://doi.org/10.1006/jcph.1997.5776) | Referencia del tratamiento viscoso de partículas |
| [Bel-Ray Synthetic Gear Oil](https://www.belray.com/product/synthetic-gear-oil/) | Referencia de lubricante conservada de V4; constantes asumidas documentadas |
| [OpenCFD, interFoam](https://doc.openfoam.com/2312/tools/processing/solvers/rtm/multiphase/interFoam/) | Fundamento y campos del cálculo bifásico; documentación 2312, ejecución efectiva 1912 |
| [QEMU](https://www.qemu.org/download/) y [Debian Bookworm](https://cloud.debian.org/images/cloud/bookworm/) | Entorno local de pruebas Linux |
| [Rajendran, Manglik y Jog](https://arxiv.org/abs/2301.01638) | Investigación de viscosidades distintas en VOF; su modificación no se implementó ni valida la causa de los fallos observados |
| [Elmer FEM](https://github.com/ElmerCSC/elmerfem) | Alternativa estudiada para electrostática futura |
| [Fuentes heredadas de V4](../research/sources.md) y [registro V4.1](../research/v41.md) | Mecanismo, aceite, decisiones, supuestos y ensayos descartados |

## 7. Límites y reproducción

El aire de SPH es inferido; el aire de OpenFOAM es una fase calculada en otra geometría. No se ha validado con un Komatsu real ni sensores comerciales. Faltan CAD y holguras autorizadas, propiedades medidas del aceite, calibración de sensores y estudios convergentes de malla y tiempo. No se calculan electromagnetismo, espuma, cavitación, desgaste o película lubricante microscópica.

Con Node, ejecutar `node server.mjs` y abrir **http://127.0.0.1:8772/**. El banco se reproduce con `bash cfd/shear_bench/Allrun` en Debian/OpenFOAM configurado. [README](../README.md) explica compilación, casos nuevos y acceso por túnel SSH. El paquete descomprimido fue probado localmente; una VM local no constituye una ejecución en un servidor externo.
