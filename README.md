# PR3: Práctica de control de versiones

## Introducción

Esta actividad permite ejercitar el flujo de trabajo con Git y un repositorio remoto. Se conservarán distintas versiones de un proyecto, se revisarán los cambios antes de registrarlos y se comprobará la sincronización entre el repositorio local y el remoto.

La práctica no incorpora nuevos contenidos de programación. El programa entregado es deliberadamente sencillo y se utiliza como material sobre el cual aplicar las operaciones de Git estudiadas anteriormente.

### Prerrequisitos

- Haber completado el laboratorio GIT
- Tener acceso a una cuenta de GitHub o del GitLab institucional
- Saber editar archivos mediante Vim y compilar un programa sencillo en C
- Reconocer el propósito de `status`, `diff`, `add`, `commit`, `push`, `log` y `show`

### Objetivo general

- Aplicar el flujo de trabajo con Git para conservar y compartir una secuencia de cambios

### Objetivos específicos

- Configurar el acceso mediante SSH al servicio remoto
- Crear y clonar un repositorio remoto
- Inspeccionar cambios en el `working directory` y el `staging`
- Organizar modificaciones relacionadas en commits separados
- Excluir un archivo generado mediante `.gitignore`
- Comprobar que el repositorio local y el remoto contienen la misma historia

### Estructura inicial

```text
workspace/
├── material/
│   ├── descripcion.txt
│   └── registro.c
├── scripts/
│   └── check.sh
└── repositorio/        <- se creará durante la actividad
```

- `material` contiene los archivos que se incorporarán al repositorio de práctica
- `scripts/check.sh` permite revisar qué actividades están completas y cuáles permanecen pendientes
- `repositorio` no existe inicialmente y se creará al clonar el `remote repository`

## Actividad

### 1. Configurar el acceso mediante SSH

Siguiendo el mismo procedimiento que en laboratorio anterior, configure su maquina virtual para poder acceder a GIT mediante SSH:

- Configurar el nombre y el correo electrónico utilizados por Git
- Comprobar que no existan llaves personales anteriores en la máquina virtual
- Generar una nueva llave SSH
- Registrar la llave pública en el servicio remoto
- Probar la conexión mediante SSH

### 2. Crear y clonar el repositorio remoto

Desde la interfaz web de GitHub o del GitLab institucional, crear un repositorio **público** con las siguientes características:

- Nombre `inf20125-pr3`
- Inicializado con un archivo `README.md`
- Sin plantilla de `.gitignore` y sin licencia

Copiar la URL SSH del repositorio. Desde `workspace`, construir el comando necesario para clonarlo en una carpeta llamada `repositorio` y entrar en ella.

Revisar la historia inicial y el estado del repositorio. En este momento solamente debería encontrarse registrado `README.md` y no debería haber cambios pendientes.

### 3. Registrar la primera versión del proyecto

Copiar `registro.c` y `descripcion.txt` desde `workspace/material` hasta la raíz del repositorio clonado.

Revisar el estado y comprobar que ambos archivos aparecen como `untracked`. Inspeccionar su contenido y seleccionar solamente estos dos archivos para el próximo commit.

Revisar nuevamente el estado y utilizar `git diff --staged` para comprobar el contenido seleccionado. Crear un commit con un mensaje que describa la incorporación del material inicial y publicarlo en el `remote`.

Comprobar que el `working directory` quede limpio y que la historia muestre el nuevo commit después de la versión inicial creada desde la web.

### 4. Registrar una nueva versión del programa

Abrir `registro.c` con Vim. El programa define `VERSION_ACTUAL` con el valor `1`. Modificar solamente esta definición para que la nueva versión utilice el valor `2`.

Antes de seleccionar el cambio, revisar el estado y la diferencia respecto del último commit. Luego incorporar `registro.c` al `staging` y volver a revisar la diferencia seleccionada.

Crear un commit que describa la actualización de versión y publicarlo. Utilizar la historia y `git show` para comprobar que la versión original y la versión actual se encuentran en commits diferentes.

### 5. Ignorar el ejecutable generado

Compilar `registro.c` con `-Wall`, `-Wextra`, `-Werror` y `-std=c11`. El ejecutable debe llamarse `registro` y quedar en la raíz del repositorio.

Ejecutar el programa y comprobar que informa la versión `2`. Revisar el estado del repositorio: el ejecutable debería aparecer como un archivo nuevo que Git todavía no registra.

Crear `.gitignore` y agregar una línea para ignorar `registro`. Revisar nuevamente el estado y comprobar que el ejecutable deja de aparecer, mientras `.gitignore` continúa disponible para ser registrado.

Seleccionar solamente `.gitignore`, crear un commit y publicarlo. El ejecutable debe permanecer en el `working directory`, pero no debe formar parte de ningún commit nuevo.

### 6. Verificar la actividad

#### 6.1. Habilitar `check.sh`

Volver a `workspace`, revisar los permisos de `scripts/check.sh` y agregar permiso de ejecución para el propietario.

#### 6.2. Ejecutar la revisión

Ejecutar `scripts/check.sh` desde `workspace`. El script permite revisar qué actividades están completas y cuáles permanecen pendientes.

La revisión utiliza solamente el repositorio local y la información disponible sobre la rama remota asociada. No modifica archivos, no crea commits y no publica ni descarga cambios.
